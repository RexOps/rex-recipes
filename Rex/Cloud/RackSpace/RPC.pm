#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Cloud::RackSpace::RPC;

use Moo;
use JSON::XS;
use LWP::UserAgent;
use HTTP::Request;
use Try::Tiny;
use Data::Dumper;
use Carp;

use constant HTTP_POST => 'POST';
use constant HTTP_GET  => 'GET';

has authentication_url => ( is => 'ro', default => 'https://identity.api.rackspacecloud.com/v2.0/tokens' );
has version            => ( is => 'ro', default => 'v2.0' );
has region             => ( is => 'ro', default => 'IAD' );
has ua                 => ( is => 'ro', default => sub { return LWP::UserAgent->new; } );
has token              => ( is => 'rwp' );
has endpoint_url       => ( is => 'rwp' );

sub authenticate {
   my ($self, $user, $key) = @_;

   confess "no user given." if(! $user);
   confess "no key given." if(! $key);
   
   my $post = {
      auth => {
         "RAX-KSKEY:apiKeyCredentials" => {
            username => $user,
            apiKey   => $key,
         },
      },
   };

   my $req = $self->_generate_request( method => HTTP_POST, url => $self->authentication_url, post => $post );
   my $ret = $self->_do_request($req);

   confess "no token found in rackspace answer." if (! exists $ret->{access}->{token}->{id});
   $self->_set_token($ret->{access}->{token}->{id});

   my ($cloud_servers) = grep { $_->{name} eq "cloudServersOpenStack" } @{ $ret->{access}->{serviceCatalog} };
   my ($endpoint) = grep { $_->{region} eq $self->region } @{ $cloud_servers->{endpoints} };
   confess "no endpoint entry found for " . $self->region if (! ref $endpoint);
   $self->_set_endpoint_url($endpoint->{publicURL});
}

sub factory {
   my ($self, $what) = @_;
   my $class = "Rex::Cloud::RackSpace::RPC::\u$what";

   eval "use $class;";
   confess "Error loading RackSpace Class \u$what" if ($@);

   return $class->new(rs => $self);
}

sub _do_request {
   my ($self, $req) = @_;

   confess "no request object given." if(! ref $req);
   my $res = $self->ua->request($req);

   if($res->is_success) {
      if($res->code == 204) {
         return { ok => 1 };
      }
      else {
         return decode_json($res->decoded_content);
      }
   }
   else {
      print Dumper($res);
      confess "error executing action.";
   }

}

sub _generate_request {
   my ($self, %param) = @_;

   confess "no http method given."     if (! exists $param{method});
   confess "no valid post data given." if ( $param{method} eq HTTP_POST && ! ref $param{post});
   confess "no action or url given."   if (! exists $param{action} && ! exists $param{url});

   my $url;

   if(exists $param{url}) {
      $url = $param{url};
   }
   else {
      $url = $self->endpoint_url . "/" . $param{action};
   }

   my @add_headers;
   if($self->token) {
      push @add_headers, (X_Auth_Token => $self->token);
   }

   if(exists $param{post}) {
      return HTTP::Request->new($param{method}, $url, [Content_Type => 'application/json', @add_headers], encode_json($param{post}));
   }
   else {
      return HTTP::Request->new($param{method}, $url, [Content_Type => 'application/json', @add_headers]);
   }
}

1;
