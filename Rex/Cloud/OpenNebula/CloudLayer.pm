#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Cloud::OpenNebula::CloudLayer - Cloud layer for Rex

=head1 DESCRIPTION

This module is a layer between the Rex::Cloud::OpenNebula Module and the Rex::Cloud API.

=head1 SYNOPSIS

 use Rex::Cloud::OpenNebula::CloudLayer;
  
 use Rex::Commands::Cloud;
 use Rex::Cloud::OpenNebula;
 use Data::Dumper;
 
 cloud_service "OpenNebula";
 cloud_auth "user", "password";
 cloud_region "http://172.16.120.131:2633/RPC2";
 
 task "list-os", sub {
    print Dumper get_cloud_operating_systems;
 };
 
 task "create", sub {
    my $params = shift;
    my $vm = cloud_instance create => {
       image        => "template-1",
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

package Rex::Cloud::OpenNebula::CloudLayer;

use strict;
use warnings;

use Data::Dumper;

use Rex::Cloud::Base;
use Rex::Cloud::OpenNebula::RPC;

use base qw(Rex::Cloud::Base);

=item new([endpoint => $url, user => $user, password => $password])

Constructor.

If you want to use the OO Interface:

 my $obj = Rex::Cloud::OpenNebula::CloudLayer->new(
              endpoint => "http://your-opennebula-server/RPC2:2633",
              user     => "username",
              password => "password"
           );

=cut

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   if(exists $self->{endpoint}) {
      $self->set_endpoint($self->{endpoint});
   }

   Rex::Logger::debug("Creating new OpenNebula CloudLayer Object, with endpoint: " . ($self->{endpoint} ? $self->{endpoint} : "not defined yet"));

   return $self;
}

=item set_auth($user, $password)

Set the authentication.

 cloud_auth "user", "password";
 
Or, if you want to use the OO Interface:

 $obj->set_auth($user, $password);

=cut

sub set_auth {
   my ($self, $user, $password) = @_;
   $self->{user} = $user;
   $self->{password} = $password;
}

=item list_operating_systems()

List all available templates.

 my @oses = get_cloud_operating_systems;

Or, if you want to use the OO interface:

 my @oses = $obj->list_operating_systems();

=cut

sub list_operating_systems {
   my ($self) = @_;

   my @templates = $self->_one->get_templates();

   my @ret = ();

   for my $tpl (@templates) {
      push(@ret, { name => $tpl->name, id => $tpl->id });
   }

   return @ret;
}

=item run_instance(%data)

Create an instance and start it.

You have to define an image_id (or template_id) to use and a name. You can also use the name of the template. Than you have to define the template property or image property.

 my $vm = cloud_instance create => {
    image_id  => 5,
    name      => $params->{name},
 };

 my $vm = cloud_instance create => {
    image  => "template-name",
    name   => $params->{name},
 };

Or, if you want to call it via its OO Interface:

 $obj->run_instance(
   iamge => "template-name",
   name  => "myinstance01",
 );

=cut

sub run_instance {
   my ($self, %data) = @_;

   my $image_id   = $data{image_id} || $data{template_id};
   my $image_name = $data{image}    || $data{template};

   my $name = $data{name};

   if(! $name) {
      die("You have to define a name.");
   }

   if(! ($image_id || $image_name)) {
      die("You have to define a image_id or image_name");
   }

   my $vm = $self->_one->create_vm(
      name     => $name,
      template => $image_id // $image_name,
   );

   my $state = $vm->state;
   while($state ne "running") {
      sleep 5; # wait 5 seconds for the next request
      $state = $vm->state;
   }

   my @nics = $vm->nics;
   my $ip = $nics[0]->ip; # get the ip of the first device

   sleep 5; # wait a few seconds to get the os time to boot

   return {
      ip => $ip,
      name => $vm->name,
      state => $vm->state,
      architecture => $vm->arch,
      id => $vm->id,
      ip_list => (sub { my @ret; for my $nic (@nics) { push(@ret, $nic->ip); } return \@ret; })->()
   };
}

=item terminate_instance(%data)

Terminate and remove an instance.

 cloud_instance terminate => "vmname";

Or, if you want to use the OO Interface:

 $obj->terminate_instance(instance_id => "vmname or vmid");

=cut

sub terminate_instance {
   my ($self, %data) = @_;
   $self->_one->get_vm($data{instance_id})->shutdown;
}

=item start_instance(%data)

Start a stopped instance.

 cloud_instance start => "vmname";

Or, if you want to use the OO Interface:

 $obj->start_instance(name => "vmname or vmid");

=cut

sub start_instance {
   my ($self, %data) = @_;
   $self->_one->get_vm($data{instance_id})->resume;
}

=item stop_instance(%data)

Stop a running instance.

 cloud_instance stop => "vmname";

Or, if you want to use the OO Interface:

 $obj->stop_instance(name => "vmname or vmid");

=cut

sub stop_instance {
   my ($self, %data) = @_;
   $self->_one->get_vm($data{instance_id})->stop;
}

=item list_instances()

List your instances. Returns an array of hashes.

 print Dumper cloud_instance_list;

Or, if you want to use the OO Interface:

 my @instances = $obj->list_instances();

=cut

sub list_instances {
   my ($self) = @_;

   my @ret = ();

   my @vms = $self->_one->get_vms;

   for my $vm (@vms) {
      my @nics = $vm->nics;
      my $ip = $nics[0]->ip;

      push(@ret, {
         ip => $ip,
         ip_list => (sub { my @ret; for my $nic (@nics) { push(@ret, $nic->ip); } return \@ret; })->(),
         name => $vm->name,
         state => $vm->state,
         architecture => $vm->arch,
         id => $vm->id,
      });
   }

   return @ret;
}

=item list_running_instances()

List your running instances. 

 group opennebula_vms => get_cloud_instances_as_group();

Or, if you want to use the OO Interface:

 my @instances = $obj->list_running_instances();

=cut

sub list_running_instances { 
   my ($self) = @_;
   return grep { $_->{"state"} eq "running" } $self->list_instances();
}

sub _one {
   my ($self) = @_;
   return Rex::Cloud::OpenNebula::RPC->new(url => $self->{__endpoint}, user => $self->{user}, password => $self->{password});
}

1;

