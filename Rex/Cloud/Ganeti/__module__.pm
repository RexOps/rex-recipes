### only list_instances is being worked on right now


package Rex::Cloud::Ganeti;

use strict;
use warnings;

use Rex::Logger;
use Rex::Cloud::Base;

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
      push(@ret, { name => $os->name, variant => $os->variant });
   }

   return @ret;
}

sub list_instances {
   my ($self) = @_;
   my @ret = ();
   my @vms = $self->_ganeti->get_vms;

   for my $vm (@vms) {
      #my @nics = $vm->nics;
      #my $ip   = $nics[0]->ip;

      push(@ret, {
         id      => $vm->name,
         #ip      => $ip,
         name    => $vm->name,
         #state   => $vm->state,
         #architecture => $vm->arch,
      });
   }

   return @ret;
}

sub list_running_instances { 
   my ($self) = @_;
   return grep { $_->{"state"} eq "running" } $self->list_instances();
}


sub run_instance {
   my ($self, %data) = @_;
   my $image_id   = $data{image_id};
   my $name = $data{name};

   if(! $name) {
      die("You have to define a name.");
   }

   if(! $image_id) {
      die("You have to define a image_id");
   }

   my $vm = $self->_ganeti->create_vm(
      name     => $name,
      template => $image_id,
   );

   # waiting until the instance has been created and started.
   my $state = $vm->state;
   while($state ne "running") {
      sleep 5; # wait 5 seconds for the next request
      $state = $vm->state;
   }

   my @nics = $vm->nics;
   my $ip   = $nics[0]->ip; # get the ip of the first device

   sleep 5; # wait a few seconds to give the os time to boot

   return {
      id    => $vm->id,
      ip    => $ip,
      name  => $vm->name,
      state => $vm->state,
      architecture => $vm->arch,
   };
}

sub stop_instance {
   my ($self, %data) = @_;
   $self->_ganeti->get_vm($data{instance_id})->stop;
}

sub terminate_instance {
   my ($self, %data) = @_;
   $self->_ganeti->get_vm($data{instance_id})->shutdown;
}

sub start_instance {
   my ($self, %data) = @_;
   $self->_ganeti->get_vm($data{instance_id})->resume;
}

sub _ganeti {
   my ($self) = @_;
   return Rex::Cloud::Ganeti::RAPI->new(url => $self->{__endpoint}, user => $self->{__user}, password => $self->{__password});
}

Rex::Cloud->register_cloud_service(ganeti => __PACKAGE__);

1;
