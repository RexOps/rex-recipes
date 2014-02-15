#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Cloud::RackSpace::RPC::Server;

use Moo;
use Carp;
use Data::Dumper;

use constant HTTP_POST   => 'POST';
use constant HTTP_GET    => 'GET';
use constant HTTP_DELETE => 'DELETE';

has rs          => ( is => 'ro' );
has access_ipv4 => ( is => 'ro' );
has access_ipv6 => ( is => 'ro' );
has addresses   => ( is => 'ro' );
has created     => ( is => 'ro' );
has flavor      => ( is => 'ro' );
has host_id     => ( is => 'ro' );
has id          => ( is => 'ro' );
has image       => ( is => 'ro' );
has links       => ( is => 'ro' );
has metadata    => ( is => 'ro' );
has name        => ( is => 'ro' );
has progress    => ( is => 'ro' );
has status      => ( is => 'ro' );
has tenant_id   => ( is => 'ro' );
has updated     => ( is => 'ro' );
has user_id     => ( is => 'ro' );
has admin_pass  => ( is => 'ro' );


sub list {
   my ($self) = @_;

   my $req = $self->rs->_generate_request(method => HTTP_GET, action => "servers/detail");
   my $ret = $self->rs->_do_request($req);

   confess "didn't get a valid server list." if(! ref $ret);

   my @ret;
   for my $entry (@{ $ret->{servers} }) {

      delete $entry->{"OS-DCF:diskConfig"};
      delete $entry->{"OS-EXT-STS:power_state"};
      delete $entry->{"OS-EXT-STS:task_state"};
      delete $entry->{"OS-EXT-STS:vm_state"};

      push @ret, __PACKAGE__->new(
                     rs      => $self->rs,
                     %{ $entry },
                 );
   }

   return @ret;
}

sub create {
   my ($self, %param) = @_;

   confess "no name given." if(! exists $param{name});
   confess "no image_id given." if(! exists $param{image_id});
   confess "no flavor_id given." if(! exists $param{flavor_id});

   my $post = {
      server => {
         name      => $param{name},
         imageRef  => $param{image_id},
         flavorRef => $param{flavor_id},
         metadata  => $param{metadata} || {},
      },
   };

   my $req = $self->rs->_generate_request(method => HTTP_POST, action => 'servers', post => $post);
   my $ret = $self->rs->_do_request($req);

   confess "error creating server. no id found." if(! exists $ret->{server}->{id});

   return $self->load($ret->{server}->{id}, admin_pass => $ret->{server}->{adminPass});
}

sub load {
   my ($self, $id, %add) = @_;

   my $req = $self->rs->_generate_request(method => HTTP_GET, action => "servers/$id");
   my $ret = $self->rs->_do_request($req);

   confess "got no server details." if(! exists $ret->{server});

   delete $ret->{"OS-DCF:diskConfig"};
   delete $ret->{"OS-EXT-STS:power_state"};
   delete $ret->{"OS-EXT-STS:task_state"};
   delete $ret->{"OS-EXT-STS:vm_state"};

   return __PACKAGE__->new(rs => $self->rs, %{ $ret->{server} }, %add);
}

sub delete {
   my ($self) = @_;

   my $req = $self->rs->_generate_request(method => HTTP_DELETE, action => "servers/" . $self->id);
   my $ret = $self->rs->_do_request($req);

   confess "error deleting server." if(! ref $ret && ! exists $ret->{ok} && $ret->{ok} != 1);
}

1;
