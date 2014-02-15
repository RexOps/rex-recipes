#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Cloud::RackSpace - RackSpace Cloud layer for Rex

=head1 DESCRIPTION

With this module you can access RackSpace cloud.

=head1 SYNOPSIS

 use Rex::Cloud::RackSpace;
 use Rex::Commands::Cloud;

 use Data::Dumper;

 cloud_service "RackSpace";
 cloud_auth "user", "api-key";
 cloud_region "IAD";

 task "list-os", sub {
    print Dumper get_cloud_operating_systems;
 };

 task "create", sub {
    my $params = shift;
    my $vm = cloud_instance create => {
       image        => "1-2-3-4",
       name         => $params->{name},
       flavor       => 'performance1-1',
       networks     => ['1-2-3-4'],
    };

    print Dumper($vm);
 };

 task "terminate", sub {
    my $params = shift;
    cloud_instance terminate => $params->{id};
 };

 task "list", sub {
    print Dumper cloud_instance_list;
 };

=head1 METHODS

=over 4

=cut

package Rex::Cloud::RackSpace;

use strict;
use warnings;

use Data::Dumper;

use Moo;
use Carp;
use Rex::Cloud::Base;
use Rex::Cloud::RackSpace::RPC;

extends 'Rex::Cloud::Base';

has endpoint => ( is => 'ro' );
has user     => ( is => 'rwp' );
has key      => ( is => 'rwp' );
has rs => ( is => 'ro', default => sub { Rex::Cloud::RackSpace::RPC->new; } );

=item new([endpoint => $url, user => $user, password => $password])

Constructor.

If you want to use the OO Interface:

 my $obj = Rex::Cloud::RackSpace->new(
              endpoint => "IAD",
              user     => "username",
              key      => "api-key"
           );

=cut

=item set_auth($user, $key)

Set the authentication.

 cloud_auth "user", "key";

Or, if you want to use the OO Interface:

 $obj->set_auth($user, $key);

=cut

sub set_auth {
  my ( $self, $user, $key ) = @_;
  $self->_set_user($user);
  $self->_set_key($key);

  $self->rs->authenticate( $user, $key );
}

=item list_operating_systems()

List all available templates.

 my @oses = get_cloud_operating_systems;

Or, if you want to use the OO interface:

 my @oses = $obj->list_operating_systems();

=cut

sub list_operating_systems {
  my ($self) = @_;

  my $images = $self->rs->factory('image');

  my @ret = ();

  for my $tpl ( $images->list ) {
    push @ret,
      {
      name     => $tpl->name,
      id       => $tpl->id,
      status   => $tpl->status,
      min_disk => $tpl->min_disk,
      min_ram  => $tpl->min_ram,
      metadata => $tpl->metadata,
      created  => $tpl->created,
      updated  => $tpl->updated,
      links    => $tpl->links,
      };
  }

  return @ret;
}

=item run_instance(%data)

Create an instance and start it.

You have to define an image, a name and a flavor.

 my $vm = cloud_instance create => {
    image  => '80fbcb55-b206-41f9-9bc2-2dd7aac6c061',
    name   => $params->{name},
    flavor => 'performance1-1',
 };

If you want to use a custom network, you can also define this.

 my $vm = cloud_instance create => {
    image    => '80fbcb55-b206-41f9-9bc2-2dd7aac6c061',
    name     => $params->{name},
    flavor   => 'performance1-1',
    networks => ['network-id'],
 };


Or, if you want to call it via its OO Interface:

 $obj->run_instance(
   iamge  => '80fbcb55-b206-41f9-9bc2-2dd7aac6c061',
   name   => 'myinstance01',
   flavor => 'performance1-1',
 );

=cut

sub run_instance {
  my ( $self, %data ) = @_;

  my $image_id = $data{image_id} || $data{image};
  my $name = $data{name};

  confess "no name given."   if ( !$name );
  confess "no image given."  if ( !$image_id );
  confess "no flavor given." if ( !exists $data{flavor} );

  my %add;
  if ( exists $data{networks} ) {
    $add{networks} = $data{networks};
  }

  my $vm = $self->rs->factory('server')->create(
    name      => $name,
    image_id  => $image_id,
    flavor_id => $data{flavor},
    %add,
  );

  my $state = $vm->state;
  while ( lc($state) ne "running" ) {
    sleep 10;    # wait 5 seconds for the next request
    $state = $vm->state;
  }

  my ($nw_addr) = grep { $_->{version} == 4 } @{ $vm->addresses()->{public} };
  my $ip = $nw_addr->{addr};    # get the ip of the ipv4 public device

  my @ips;
  for my $nw ( keys %{ $vm->addresses() } ) {
    for my $ip ( @{ $vm->addresses()->{$nw} } ) {
      push @ips, $ip->{addr};
    }
  }

  return {
    ip      => $ip,
    name    => $vm->name,
    state   => $vm->state,
    id      => $vm->id,
    ip_list => [@ips],
  };
}

=item terminate_instance(%data)

Terminate and remove an instance.

 cloud_instance terminate => "instance-id";

Or, if you want to use the OO Interface:

 $obj->terminate_instance(instance_id => "instance-id");

=cut

sub terminate_instance {
  my ( $self, %data ) = @_;

  confess "no instance_id given." if ( !exists $data{instance_id} );

  my $vm = $self->rs->factory('server')->load( $data{instance_id} )->delete;
}

=item start_instance(%data)

Start a stopped instance. This is not available for RackSpace Cloud.

=cut

sub start_instance {
  my ( $self, %data ) = @_;
  confess "not available for RackSpace Cloud.";
}

=item stop_instance(%data)

Stop a running instance. This is not available for RackSpace Cloud.

=cut

sub stop_instance {
  my ( $self, %data ) = @_;
  confess "not available for RackSpace Cloud.";
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

  my @vms = $self->rs->factory('server')->list;

  for my $vm (@vms) {
    my ($nw_addr) = grep { $_->{version} == 4 } @{ $vm->addresses()->{public} };
    my $ip = $nw_addr->{addr};    # get the ip of the ipv4 public device

    my @ips;
    for my $nw ( keys %{ $vm->addresses() } ) {
      for my $ip ( @{ $vm->addresses()->{$nw} } ) {
        push @ips, $ip->{addr};
      }
    }

    push(
      @ret,
      {
        ip      => $ip,
        ip_list => [@ips],
        name    => $vm->name,
        state   => $vm->state,
        id      => $vm->id,
      }
    );
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
  return grep { lc( $_->{"state"} ) eq "running" } $self->list_instances();
}

=item create_network()

Create a new network.

 my $net = cloud_network create => {
    network => '192.168.0.0/24',
    name    => 'mynetwork',
 };

Or, if you want to use the OO Interface:

 my $net = $obj->create_network(
    network => '192.168.0.0/24',
    name    => 'mynetwork',
 );


=cut

sub create_network {
  my ( $self, %data ) = @_;

  confess "no network given." if ( !exists $data{network} );
  confess "no name given."    if ( !exists $data{name} );

  my $net = $self->rs->factory('network')->create(
    cidr  => $data{network},
    label => $data{name},
  );

  confess "error creating network." if ( !ref $net && !exists $net->{id} );

  return {
    network => $net->cidr,
    name    => $net->label,
    id      => $net->id,
  };
}

=item list_networks

List the networks of your RackSpace Cloud.

 print Dumper cloud_network_list;

Or, if you want to use the OO Interface:

 my @networks = $obj->list_networks;

=cut

sub list_networks {
  my ($self) = @_;

  my @nets = $self->rs->factory('network')->list;

  my @ret;
  for my $net (@nets) {
    push @ret,
      {
      name    => $net->label,
      network => $net->cidr,
      id      => $net->id,
      };
  }

  return @ret;
}

=item delete_network($network_id)

Delete a network from the cloud. You have to make sure that the network is not used by any VM.

 cloud_network delete => $network_id;

Or, if you want to use the OO Interface:

 $obj->delete_network($network_id);

=cut

sub delete_network {
  my ( $self, $network_id ) = @_;

  confess "no network-id given." if ( !$network_id );
  $self->rs->factory('network')->load($network_id)->delete;
}

=item list_volumes

List all known volumes. Returns a list (array) of all volumes.

=cut

sub list_volumes {
  my ($self) = @_;

  $self->rs->factory('storage')->list;

  # my @volumes;
  # for my $vol (@{$ref->{"volumeSet"}->{"item"}}) {
  #   push(@volumes, {
  #     id => $vol->{"volumeId"},
  #     status => $vol->{"status"},
  #     zone => $vol->{"availabilityZone"},
  #     size => $vol->{"size"},
  #     attached_to => $vol->{"attachmentSet"}->{"item"}->{"instanceId"},
  #   });
  # }
  #
  # return @volumes;
}

=item create_volume(%option)

Create a new storage volume.

 cloud_volume create => {
   size         => 100, #smalest entity at rackspace
   name         => 'the name', # optional
   description  => 'the description', # optional
   snapshot_id  => 'The optional snapshot from which to create a volume.', # optional
   volume_type  => 'SATA | SAS', # optional, default is SATA
   source_volid => 'The source identifier of an existing Cloud Block Storage volume that you want to clone (copy) to create a new volume.', # optional
   metadata     => 'This optional parameter is available if you want to set any metadata values on the volume.', # optional
 };

Or, if you want to use the OO Interface:

 $obj->create_volume(
   size         => 100, #smalest entity at rackspace
   name         => 'the name', # optional
   description  => 'the description', # optional
   snapshot_id  => 'The optional snapshot from which to create a volume.', # optional
   volume_type  => 'SATA | SAS', # optional, default is SATA
   source_volid => 'The source identifier of an existing Cloud Block Storage volume that you want to clone (copy) to create a new volume.', # optional
   metadata     => 'This optional parameter is available if you want to set any metadata values on the volume.', # optional
 };

=cut

sub create_volume {
  my ( $self, %option ) = @_;

  $option{size} ||= '100';
  $option{size} = 100 if ( $option{size} < 100 ); # smallest entity at rackspace

  my $data = $self->rs->factory('storage')->create(%option);
  return $data->{id};
}

=item delete_volume(%option)

Delete a cloud storage volume.

 cloud_volume delete => 'storage-id'

Or, if you want to use the OO Interface:

 $obj->delete_volume(volume_id => 'storage-id');

=cut

sub delete_volume {
  my ( $self, %option ) = @_;
  return $self->rs->factory('storage')->delete(%option);
}

sub attach_volume {
  my ($self, %option) = @_;
  $self->rs->factory('storage')->attach(%option);
}

sub detach_volume {
  my ($self, %option) = @_;
  $self->rs->factory('storage')->detach(%option);
}

1;
