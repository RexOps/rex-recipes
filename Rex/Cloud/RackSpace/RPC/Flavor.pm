#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Cloud::RackSpace::RPC::Flavor;

use Moo;
use Carp;
use Data::Dumper;

use constant HTTP_POST => 'POST';
use constant HTTP_GET  => 'GET';

has rs          => ( is => 'ro' );
has name        => ( is => 'rwp' );
has id          => ( is => 'rwp' );
has ram         => ( is => 'rwp' );
has vcpus       => ( is => 'rwp' );
has swap        => ( is => 'rwp' );
has rxtx_factor => ( is => 'rwp' );
has disk        => ( is => 'rwp' );
has links       => ( is => 'rwp' );

sub list {
  my ($self) = @_;

  my $req =
    $self->rs->_generate_request( method => HTTP_GET, action => "flavors" );
  my $ret = $self->rs->_do_request($req);

  confess "didn't get a valid flavor list." if ( !ref $ret );

  my @ret;
  for my $entry ( @{ $ret->{flavors} } ) {

    delete $entry->{"OS-FLV-WITH-EXT-SPECS:extra_specs"};
    delete $entry->{"OS-FLV-EXT-DATA:ephemeral"};

    push @ret,
      __PACKAGE__->new(
      rs => $self->rs,
      %{$entry},
      );
  }

  return @ret;
}

1;
