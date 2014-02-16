#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Cloud::RackSpace::RPC::Network;

use Moo;
use Carp;
use Data::Dumper;

use constant HTTP_POST   => 'POST';
use constant HTTP_GET    => 'GET';
use constant HTTP_DELETE => 'DELETE';

has rs    => ( is => 'ro' );
has id    => ( is => 'rwp' );
has cidr  => ( is => 'rwp' );
has label => ( is => 'rwp' );


sub list {
   my ($self) = @_;

   my $req = $self->rs->_generate_request(method => HTTP_GET, action => "os-networksv2");
   my $ret = $self->rs->_do_request($req);

   confess "didn't get a valid network list." if(! ref $ret);

   my @ret;
   for my $entry (@{ $ret->{networks} }) {

      push @ret, __PACKAGE__->new(
                     rs      => $self->rs,
                     %{ $entry },
                 );
   }

   return @ret;
}

sub create {
   my ($self, %param) = @_;

   confess "no cidr given."  if (! exists $param{cidr});
   confess "no label given." if (! exists $param{label});

   my $post = {
      network => {
         cidr  => $param{cidr},
         label => $param{label},
      },
   };

   my $req = $self->rs->_generate_request(method => HTTP_POST, action => "os-networksv2", post => $post);
   my $ret = $self->rs->_do_request($req);

   return $self->load($ret->{network}->{id});
}

sub load {
   my ($self, $id, %add) = @_;

   my $req = $self->rs->_generate_request(method => HTTP_GET, action => "os-networksv2/$id");
   my $ret = $self->rs->_do_request($req);

   confess "got no network details." if(! exists $ret->{network});

   return __PACKAGE__->new(rs => $self->rs, %{ $ret->{network} }, %add);
}

sub delete {
   my ($self) = @_;

   confess "no network id found." if (! $self->id);

   my $req = $self->rs->_generate_request(method => HTTP_DELETE, action => "os-networksv2/" . $self->id);
   my $ret = $self->rs->_do_request($req);

   confess "error deleting network." if(! ref $ret && ! exists $ret->{ok} && $ret->{ok} != 1);
}


1;
