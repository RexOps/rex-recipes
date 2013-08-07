package Rex::Cloud::Ganeti;

use strict;
use warnings;

use Data::Dumper;
use Rex::Logger;
use Rex::Cloud::Base;
use Rex::Cloud::Ganeti::RAPI;


use parent qw/ Rex::Cloud::Base /;

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
   $self->{__endpoint} = $endpoint;
}

sub set_auth {
   my ($self, $user, $password) = @_;
   $self->{__user}     = $user;
   $self->{__password} = $password;
}

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

sub list_running_instances {
   my $self = shift;
   
   # "running" means if instance is set to be running and actually is
   return grep { $_->{state} eq 'running' } $self->list_instances();
}


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
   
   Rex::Logger::debug(Dumper(%data) . Dumper(%p));
   
   my $job = $self->_ganeti->create_vm(%data, %p);
   
   # i need to poll the job until it get status "success".
   # or return if job get "error" status.
   my $state;
   while($state = $job->status) {
      Rex::Logger::debug("job ". $job->id ." has state: $state");
      if($state eq "success") {
         my $vm = $self->_ganeti->get_vm($p{instance_name});
         return {
            name         => $vm->name,
            state        => $vm->status,
            id           => $vm->name,
            ip           => $vm->ip, ### WARN, $vm->ip will return the instance's hostname.
            architecture => $vm->arch,
         };
      } elsif($state eq "error") {
         warn("Instance ". $p{instance_name} ." creation failed");
         return;
      }
      sleep 5;
      
   }

}

# sub run_instance {
   # my ($self, %data) = @_;
   # my $os_name   = $data{os};
   # my $os_variant = $data{variant} || "default";

   # if(! $os_name) {
      # die("You have to define an os.");
   # }

   # my $vm = $self->_ganeti->create_vm(
      # name     => $name,
      # template => $image_id,
   # );

   # # waiting until the instance has been created and started.
   # my $state = $vm->state;
   # while($state ne "running") {
      # sleep 5; # wait 5 seconds for the next request
      # $state = $vm->state;
   # }

   # my @nics = $vm->nics;
   # my $ip   = $nics[0]->ip; # get the ip of the first device

   # sleep 5; # wait a few seconds to give the os time to boot

   # return {
      # id    => $vm->id,
      # ip    => $ip,
      # name  => $vm->name,
      # state => $vm->state,
      # architecture => $vm->arch,
   # };
# }

################ $data{instance_id} is given by the Rex api
sub stop_instance {
   my ($self, %data) = @_;
   
   my $job = $self->_ganeti->get_vm($data{instance_id})->stop;
   
   my $state;
   while($state = $job->status) {
      Rex::Logger::debug("job ". $job->id ." has state: $state");
      if($state eq "success") {
         return "success";
      } elsif($state eq "error") {
         warn("Instance ". $data{instance_id} ." failed to stop");
         return;
      }
      sleep 5;
      
   }
   return; # there should be some kind of timeout to prevent looping if something
            # unknown happens to the job...
}

sub terminate_instance {
   my ($self, %data) = @_;
   
   my $job = $self->_ganeti->get_vm($data{instance_id})->remove;
   my $state;
   while($state = $job->status) {
      Rex::Logger::debug("job ". $job->id ." has state: $state");
      if($state eq "success") {
         return "success";
      } elsif($state eq "error") {
         warn("Instance ". $data{instance_id} ." failed to stop");
         return;
      }
      sleep 5;
      
   }
   return; # there should be some kind of timeout to prevent looping if something
            # unknown happens to the job...   
}

sub start_instance {
   my ($self, %data) = @_;
   my $job = $self->_ganeti->get_vm($data{instance_id})->resume;
   
   my $state;
   while($state = $job->status) {
      Rex::Logger::debug("job ". $job->id ." has state: $state");
      if($state eq "success") {
         return "success";
      } elsif($state eq "error") {
         warn("Instance ". $data{instance_id} ." failed to stop");
         return;
      }
      sleep 5;
      
   }
   return; # there should be some kind of timeout to prevent looping if something
            # unknown happens to the job...   
}

# FIXME: Not implemented yet.
sub add_tag {
   my ($self, %data) = @_;
   
   ### Tags in ganeti are just names, without values.
   ###Rex::Logger::debug("Adding a new tag: " . $data{id} . " -> " . $data{name});
   
}

sub _ganeti {
   my ($self) = @_;
   return Rex::Cloud::Ganeti::RAPI->new(host     => $self->{__endpoint},
                                        user     => $self->{__user},
                                        password => $self->{__password}
                                       );
}

Rex::Cloud->register_cloud_service(ganeti => __PACKAGE__);

1;
