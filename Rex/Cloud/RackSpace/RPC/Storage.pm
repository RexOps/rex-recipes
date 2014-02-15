#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Cloud::RackSpace::RPC::Storage;

use Moo;
use Carp;
use Data::Dumper;

use constant HTTP_POST   => 'POST';
use constant HTTP_GET    => 'GET';
use constant HTTP_DELETE => 'DELETE';

has rs                  => ( is => 'ro' );
has created_at          => ( is => 'rwp' );
has id                  => ( is => 'rwp' );
has display_name        => ( is => 'rwp' );
has display_description => ( is => 'rwp' );
has size                => ( is => 'rwp' );
has volume_type         => ( is => 'rwp' );
has snapshot_id         => ( is => 'rwp' );
has attachments         => ( is => 'rwp' );

sub list {
  my ($self) = @_;

  my $req = $self->rs->_generate_request(
    method   => HTTP_GET,
    action   => "volumes",
    endpoint => "block_storage",
  );
  my $ret = $self->rs->_do_request($req);

  confess "didn't get a valid block image list." if ( !ref $ret );

  print Dumper $ret;

  # my @ret;
  # for my $entry ( @{ $ret->{images} } ) {
  #
  #   $entry->{min_disk} = $entry->{minDisk};
  #   $entry->{min_ram}  = $entry->{minRam};
  #
  #   delete $entry->{"OS-DCF:diskConfig"};
  #   delete $entry->{minDisk};
  #   delete $entry->{minRam};
  #
  #   push @ret,
  #     __PACKAGE__->new(
  #     rs => $self->rs,
  #     %{$entry},
  #     );
  # }
  #
  # return @ret;
}

sub create {
  my ( $self, %option ) = @_;

  confess "No size given." if ( !exists $option{size} );

  my $post = {
    size                => $option{size},
    display_description => ( $option{description} || $option{name} || "" ),
    display_name => $option{name} || "",
  };

  delete $option{description};
  delete $option{name};
  delete $option{size};

  $post = { %{$post}, %option };

  my $req = $self->rs->_generate_request(
    method   => HTTP_POST,
    action   => 'volumes',
    post     => { volume => $post },
    endpoint => "block_storage",
  );
  my $ret = $self->rs->_do_request($req);

  confess "error creating block storage. no id found."
    if ( !exists $ret->{volume}->{id} );

  return $ret->{volume};
}

sub delete {
  my ( $self, %option ) = @_;

  my $vol_id = $option{volume_id};

  confess "No volume_id given." if ( !$vol_id );

  my $req = $self->rs->_generate_request(
    method   => HTTP_DELETE,
    action   => "volumes/$vol_id",
    endpoint => "block_storage",
  );
  $self->rs->_do_request($req);

  return 1;
}

sub attach {
  my ( $self, %option ) = @_;

  confess "No volume_id given." if ( !exists $option{volume_id} );
  confess "No server_id given." if ( !exists $option{server_id} );

  my $post = {
    volumeAttachment => {
      device   => $option{device_name},
      volumeId => $option{volume_id},
    }
  };

  my $req = $self->rs->_generate_request(
    method => HTTP_POST,
    action => "servers/$option{server_id}/os-volume_attachments",
    post   => $post,
  );

  my $ret = $self->rs->_do_request($req);
}

sub detach {
  my ( $self, %option ) = @_;

  confess "No volume_id given." if ( !exists $option{volume_id} );
  confess "No server_id given." if ( !exists $option{server_id} );

  $option{attach_id} ||= $option{volume_id};

  my $req = $self->rs->_generate_request(
    method => HTTP_DELETE,
    action =>
      "servers/$option{server_id}/os-volume_attachments/$option{attach_id}",
  );

  my $ret = $self->rs->_do_request($req);
}

1;
