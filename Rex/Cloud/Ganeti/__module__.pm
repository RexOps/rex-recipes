#
# (c) Joris De Pooter <jorisd@gmail.com>
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

# Some of the code is based on Rex::Cloud::OpenNebula

=head1 NAME

Rex::Cloud::Ganeti - Cloud layer for Rex

=head1 DESCRIPTION

This module provides access to Ganeti's 2.x RAPI.

It only supports HTTPS, and you are required to provide a username
and a password.

=head1 SYNOPSIS

 use Rex::Cloud::Ganeti;
  
 use Rex::Commands::Cloud;
 use Data::Dumper;
 
 cloud_service "Ganeti";
 cloud_auth "user", "password";
 cloud_region "172.16.120.131:5080";
 
 task "list-os", sub {
    print Dumper get_cloud_operating_systems;
 };
 
 task "create", sub {
    my $params = shift;
    my $vm = cloud_instance create => {
       os_type      => "debootstrap+default",
       size         => "10G",
       name         => $params->{name},
    };
 
    print Dumper($vm);
 };
 
 task "start", sub {
    my $params = shift;
    cloud_instance start => $params->{name};
 };
 
 task "stop", sub {
    my $params = shift;
    cloud_instance stop => $params->{name};
 };
 
 task "terminate", sub {
    my $params = shift;
    cloud_instance terminate => $params->{name};
 };
 
 task "list", sub {
    print Dumper cloud_instance_list;
 };

=head1 METHODS

=over 4

=cut



package Rex::Cloud::Ganeti;

use strict;
use warnings;

use Data::Dumper;
use Rex::Logger;
use Rex::Cloud::Base;
use Rex::Cloud::Ganeti::RAPI;


use parent qw/ Rex::Cloud::Base /;

=item new([endpoint => $url, user => $user, password => $password])

Constructor.

If you want to use the OO Interface:

 my $obj = Rex::Cloud::Ganeti->new(
              endpoint => "your-ganeti-server:5080",
              user     => "username",
              password => "password"
           );

=cut

sub new {
   my $class = shift;
   my $proto = ref($class) || $class;
   my $self = { @_ };

   bless($self, $proto);

   Rex::Logger::debug("Creating new Rex::Cloud::Ganeti Object, with endpoint ".
                       ($self->{endpoint} ? $self->{endpoint} : "not defined yet")
                     );
   return $self;
}

sub set_endpoint {
   my ($self, $endpoint) = @_;
   $self->{endpoint} = $endpoint;
}

=item set_auth($user, $password)

Set the authentication.

 cloud_auth "user", "password";
 
Or, if you want to use the OO Interface:

 $obj->set_auth($user, $password);

=cut

sub set_auth {
   my ($self, $user, $password) = @_;
   $self->{user}     = $user;
   $self->{password} = $password;
}

=item list_operating_systems()

List all available OSes.

 my @oses = get_cloud_operating_systems;

Or, if you want to use the OO interface:

 my @oses = $obj->list_operating_systems();

=cut

sub list_operating_systems {
   my $self = shift;

   my @oses = $self->_ganeti->get_oses;
   my @ret = ();

   for my $os (@oses) {
      push(@ret, {
         name => $os->name,
         variant => $os->variant,
         });
   }

   return @ret;
}

=item list_instances()

List your instances. Returns an array of hashes.

 print Dumper cloud_instance_list;

Or, if you want to use the OO Interface:

 my @instances = $obj->list_instances();

=cut

sub list_instances {
   my $self = shift;
   my @ret = ();
   
   my @vms = $self->_ganeti->get_vms;

   for my $vm (@vms) {

      push(@ret, {
         id           => $vm->name,
         ip           => $vm->ip,  ### WARN, $vm->ip will return the instance's hostname
         name         => $vm->name,
         state        => $vm->status,
         architecture => $vm->arch,
      });
      
   }

   return @ret;
}

=item list_running_instances()

List your running instances. 

 group ganeti_vms => get_cloud_instances_as_group();

Or, if you want to use the OO Interface:

 my @instances = $obj->list_running_instances();

=cut

sub list_running_instances {
   my $self = shift;
   # "running" means if instance is set to be running and actually is
   return grep { $_->{state} eq 'running' } $self->list_instances();

}

=item run_instance(%data)

Create an instance.

You have to define an OS, size of disk and a name.

 my $vm = cloud_instance create => {
    os_type  => "debootstrap+default",
    name     => $params->{name},
    size     => "10G",
 };

Or, if you want to call it via its OO Interface:

 $obj->run_instance(
   os_type => "debootstrap+default",
   name    => "myinstance01.foobar.com",
   size    => "10G",
 );
 
This function support a lot of parameters, see :
http://docs.ganeti.org/ganeti/2.5/html/rapi.html#id17
=cut

### http://docs.ganeti.org/ganeti/2.5/html/rapi.html
### some info are found in doc/api.rst from ganeti
### man gnt-instance(8) also
sub run_instance {

   my ($self, %data) = @_;
   
   my %p; #actual params that I will use for the REST HTTP request
   
   $p{__version__} = 1; # mandatory!
   
   $p{os_type}       = $data{os} || $data{os_type}; # mandatory!
   $p{instance_name} = $data{name}; # name is mandatory
   
   ############ disk default ##########
   my $size = $data{size}; # 'size' is mandatory, unless 'disks' is specified
   if($data{disks}) {
      $p{disks} = $data{disks};
   } else {
      
      if($size) {
         $p{disks}[0]{size} = $size if $size;
         $p{disks}[0]{mode} = 'rw'; # I force rw, because i don't think ro is useful for me
      }
   }


   
   ############ net defaults  ##########
   # if the user supplied its own nics, use them.
   my $mac = $data{mac};
   my $ip  = $data{ip};
   if($data{nics}) {
      $p{nics} = $data{nics};
   } else {
      
      $p{nics}[0]{mac} = $mac if $mac;
      $p{nics}[0]{ip}  = $ip if $ip;
   }
   

   
   
   ############ backend defaults ##########
   my $memory        = $data{ram} || $data{memory};
   my $vcpus         = $data{vcpus};
   
   # if the user supplied its own beparams, use them.
   if($data{beparams}) {
      $p{beparams} = $data{beparams};
   } else {
      
      # we'll construct beparams from given settings, if any
      $p{beparams}{memory} = $memory if $memory;
      $p{beparams}{vcpus} = $vcpus if $vcpus;
      
   }
   
   ############ hvparams defaults ##########   
   # I don't use hvparams, but maybe some people do ?
   if($data{hvparams}) {
      $p{hvparams} = $data{hvparams};
   }

   ############ misc. ############
   $p{disk_template} = $data{disk_template} || 'drbd'; # i force drbd, because it is ganeti main point imho
   
   # I don't know if I should force some missing settings values...
   $p{mode}          = $data{mode} || 'create';
   $p{hypervisor}    = $data{hypervisor}; # the cluster sets a default hypervisor value if it is missing   
      
   ####### Now I can delete keys I don't need anymore,
   ####### because Ganeti won't like json keys with null values sometimes
   
   if(! $p{instance_name}) {
      die("You must define a name for the instance");
   } else {
      delete $data{name};
   }
   
   if(! $p{os_type}) {
      die("No os defined");
   }
   delete $data{os};
   delete $data{os_type};
      
   
   if(! $p{disk_template}) {
      Rex::Logger::debug("No 'disk_template' defined (drbd, file, etc...). Using cluster's default");
      delete $p{disk_template};
   }
   delete $data{disk_template};
   
   if(! $p{nics}) {
      Rex::Logger::debug("No 'nics' or 'mac' ( 'mac' => 'XX:YY:...' ) defined. Using cluster's default");
      delete $p{nics};
   }
   delete $data{mac};
   delete $data{ip};
   delete $data{nics};
   
   if(! $p{beparams}) {
      Rex::Logger::debug("No 'beparams' or ( 'ram' and 'vcpus') defined. Using cluster's default");
      delete $p{beparams};
   }
   delete $data{beparams};
   
   if(! $p{hypervisor}) {
      delete $p{hypervisor};
   }
   delete $data{mode};
   delete $data{hypervisor};
   delete $data{ram};
   delete $data{memory};
   delete $data{vcpus};
   delete $data{hvparams};
   delete $data{size};
   delete $data{disks};
   
   ### now I must delete everything that is undef,
   ### (keys that are given by Rex::Commands::Cloud that Ganeti won't understand/need)
   foreach my $key ( keys %data ) {
      delete $data{$key} unless defined $data{$key};
   }
   
   #### end of sanitizing. 
   
   #Rex::Logger::debug(Dumper(%data) . Dumper(%p));
   
   my $job = $self->_ganeti->create_vm(%data, %p);
   
   
   my $state = $job->wait;
   if($state eq 'success') {
         my $vm = $self->_ganeti->get_vm($p{instance_name});
         return {
            name         => $vm->name,
            state        => $vm->status,
            id           => $vm->name,
            ip           => $vm->ip, ### WARN, $vm->ip will return the instance's hostname.
            architecture => $vm->arch,
         };
   } else {
     warn('Instance '. $p{instance_name} .' creation failed');
         return;
   }
     
   return; # i shouldn't be ever here.

}

=item stop_instance(%data)

Stop a running instance.

 cloud_instance stop => "vmname.foobar.com";

Or, if you want to use the OO Interface:

 $obj->stop_instance(instance_id => "vmname.foobar.com");

=cut

################ $data{instance_id} is given by the Rex api
sub stop_instance {
   my ($self, %data) = @_;
   
   my $job = $self->_ganeti->get_vm($data{instance_id})->stop;
   my $state = $job->wait;
   
   warn('Instance '. $data{instance_id} .' failed to stop')  if $state ne 'success';
   
   return $state;   
}

=item terminate_instance(%data)

Terminate and remove an instance.

 cloud_instance terminate => "vmname.foobar.com";

Or, if you want to use the OO Interface:

 $obj->terminate_instance(instance_id => "vmname.foobar.com");

=cut

sub terminate_instance {
   my ($self, %data) = @_;
   
   my $job = $self->_ganeti->get_vm($data{instance_id})->remove;
   my $state = $job->wait;
   
   warn('Instance '. $data{instance_id} .' failed to suppress')  if $state ne 'success';
   
   return $state;
}

=item start_instance(%data)

Start a stopped instance.

 cloud_instance start => "vmname.foobar.com";

Or, if you want to use the OO Interface:

 $obj->start_instance(instance_id => "vmname.foobar.com");

=cut

sub start_instance {
   my ($self, %data) = @_;

   my $job = $self->_ganeti->get_vm($data{instance_id})->resume;
   my $state = $job->wait;
   
   warn('Instance '. $data{instance_id} .' failed to start')  if $state ne 'success';
   
   return $state;
}

=item add_tag(%data)

Tags something. Currently, only a VM instance can be tagged.

 $obj->add_tag(instance_id => "vmname.foobar.com", tag = "dbprod");
 
You can also tag several identifiers at once : 
 
 $obj->add_tag(instance_id => "vmname.foobar.com", tag => [ "dbprod", "mysql", "slave" ]);

=cut

#    Tags in ganeti are just names, without values.
#    It is possible to set tags on cluster, nodes, and instances.
#    But for now, setting a tag is only for instances.
# 

sub add_tag {
   my ($self, %data) = @_;

   my $job;
   my $what;
   
   # if we're being asked to tag a VM
   if(exists($data{instance_id})) {
      $what = $data{instance_id};
      $job  = $self->_ganeti->get_vm($data{instance_id})->add_tag($data{tag});
   }

   my $state = $job->wait;

   warn("Failed to tag $what") if $state ne 'success';
   
}

sub _ganeti {
   my ($self) = @_;
   return Rex::Cloud::Ganeti::RAPI->new(host     => $self->{endpoint},
                                        user     => $self->{user},
                                        password => $self->{password}
                                       );
}

Rex::Cloud->register_cloud_service(ganeti => __PACKAGE__);

1;
