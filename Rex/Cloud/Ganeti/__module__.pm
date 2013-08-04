### only instances / vm stuff is being worked on right now


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

   Rex::Logger::debug("Creating new Rex::Cloud::Ganeti Object");

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
   my ($self) = @_;

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
   my ($self) = @_;
   my @ret = ();
   my @vms = $self->_ganeti->get_vms;

   for my $vm (@vms) {
      #Rex::Logger::debug("heres my VM" . Dumper($vm));
      #my @nics = $vm->nics;
      #my $ip   = $nics[0]->ip;

      push(@ret, {
         id      => $vm->name,
         #ip      => $ip,
         name    => $vm->name,
         state   => $vm->status,
         #architecture => $vm->arch,
      });
      
   }

   return @ret;
}

sub list_running_instances {
   my ($self) = @_;
   
   return grep { $_->{state} eq "running" } $self->list_instances();
}


### http://docs.ganeti.org/ganeti/2.5/html/rapi.html
### some info are found in doc/api.rst from ganeti
### man gnt-instance(8) also
sub run_instance {

   my ($self, %data) = @_;
   
   my %p; #params
   
   $p{__version__} = 1; # mandatory!
   
   $p{os_type}       = $data{os} || $data{os_type};
   $p{instance_name} = $data{name};
   
   ############ disk default ##########
   my $size = $data{size} || '10G'; # default size of the 1st disk
   $p{disks} = $data{disks} || [ { size => $size, mode => 'rw' } ];
   
   
   
   
   ############ net default  ##########
   my $mac = $data{mac};
   $p{nics} = $data{nics} || [ { mac => $mac } ];
   
   
   $p{disk_template} = $data{disk_template};
   
   # I don't know if I should force some missing settings values...
   $p{mode}          = $data{mode} || 'create';
   $p{hypervisor}    = $data{hypervisor} || 'kvm';
   
   my $memory        = $data{ram} || $data{memory} || '1G';
   my $vcpus         = $data{vcpus} || 1;
   
   # if the user supplied its own beparams, use them.
   $p{beparams}      = $data{beparams} || { memory => $memory, vcpus => $vcpus };
   
   # I don't use hvparams, maybe some people do ?
   $p{hvparams}      = $data{hvparams} || {};
   
   
   
   ####### Now I can delete keys I don't need anymore,
   ####### because Ganeti won't like json keys with null values
   ### FIXME : I need to determine what options are required
   ### and die if one of them is missing
   
   if(! $p{instance_name}) {
      die("You must define a name for the instance");
   } else {
      delete $data{name};
   }
   
   if(! $p{os_type}) {
      Rex::Logger::debug("No os_type defined");
      delete $p{os_type};
   }
   delete $data{os};
   delete $data{os_type};
      
   
   if(! $p{disk_template}) {
      Rex::Logger::debug("No disk_template defined (drbd or file, etc...)");
      delete $p{disk_template};
   }
   delete $data{disk_template};
   
   if(! $p{nics}) {
      Rex::Logger::debug("No 'nics' or 'mac' ( 'mac' => 'XX:YY:...' ) defined");
   }
   delete $data{mac};
   delete $data{nics};
   
   if(! $p{beparams}) {
      Rex::Logger::debug("No 'beparams' or ( 'ram' and 'vcpus') defined");
   }
   delete $data{beparams};
   
   
   delete $data{mode};
   delete $data{hypervisor};
   delete $data{ram};
   delete $data{memory};
   delete $data{vcpus};
   delete $data{hvparams};
   delete $data{size};
   delete $data{disks};
   
   ### now I must delete everything that is undef,
   ### (keys that are given by Rex API that Ganeti doesn't understand/need)
   foreach my $key ( keys %data ) {
      delete $data{$key} unless defined $data{$key};
   }
   
   #### end of sanitizing. 
   
   Rex::Logger::debug(Dumper(%data) . Dumper(%p));
   
   return $self->_ganeti->create_vm(%data, %p);

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
   $self->_ganeti->get_vm($data{instance_id})->stop;
}

sub terminate_instance {
   my ($self, %data) = @_;
   $self->_ganeti->get_vm($data{instance_id})->remove;
}

sub start_instance {
   my ($self, %data) = @_;
   $self->_ganeti->get_vm($data{instance_id})->resume;
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
