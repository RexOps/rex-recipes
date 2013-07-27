package Rex::Cloud::Ganeti::RAPI;

use Data::Dumper;
use HTTP::Lite;
use JSON;


use Rex::Cloud::Ganeti::RAPI::Host;
use Rex::Cloud::Ganeti::RAPI::VM;

use strict;
use warnings;

sub new {
   my $class = shift;
   my $proto = ref($class) || $class;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub get_vms {
   my $self = shift;

   my $data = decode_json $self->_http("GET",
                                       "/2/instances",
                                       $self->{url}, # is http://xxx.yyy.zzz in fact
                                       );

   print Dumper($data);

   my @ret = ();

   for my $vm (@{ $data }) {
      push(@ret, Rex::Cloud::Ganeti::RAPI::VM->new(rapi => $self, data => $vm));
   }

   return @ret;
}

sub _http {
   my $self = shift;
   my ($method, $url, $host) = @_;

   if($method eq "GET") {

     my $http = HTTP::Lite->new;
     $http->method($method);

     my $encoded = encode_base64("$self->{user}:$self->{password}");
     $http->add_req_header("Authorization", $encoded);
     my $req = $http->request("$host$url");
   
     my $body = $http->body;

     Rex::Logger::debug("Got $body for response");
     return $http->body;
   }

   # FIXME: handle POST aswell 

}
