#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Cloud::RackSpace::RPC::Image;

use Moo;
use Carp;
use Data::Dumper;

use constant HTTP_POST => 'POST';
use constant HTTP_GET  => 'GET';

has rs       => ( is => 'ro' );
has created  => ( is => 'rwp' );
has id       => ( is => 'rwp' );
has metadata => ( is => 'rwp' );
has min_disk => ( is => 'rwp' );
has min_ram  => ( is => 'rwp' );
has name     => ( is => 'rwp' );
has status   => ( is => 'rwp' );
has updated  => ( is => 'rwp' );
has links    => ( is => 'rwp' );


sub list {
   my ($self) = @_;

   my $req = $self->rs->_generate_request(method => HTTP_GET, action => "images/detail");
   my $ret = $self->rs->_do_request($req);

   confess "didn't get a valid image list." if(! ref $ret);

   my @ret;
   for my $entry (@{ $ret->{images} }) {

      $entry->{min_disk} = $entry->{minDisk};
      $entry->{min_ram}  = $entry->{minRam};

      delete $entry->{"OS-DCF:diskConfig"};
      delete $entry->{minDisk};
      delete $entry->{minRam};

      push @ret, __PACKAGE__->new(
                     rs      => $self->rs,
                     %{ $entry },
                 );
   }

   return @ret;
}

1;
