package Rex::Cloud::Ganeti::RAPI;

use Data::Dumper;
use Net::HTTPS;
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

   # I first get a basic list of instances
   my $data = decode_json $self->_http("GET",
                                       "/2/instances",
                                       $self->{host},
                                       );

   Rex::Logger::debug("this is my data" . Dumper($data));

   my @ret = ();

   for my $vm (@{ $data }) {
      
      # for each VM, i need to dig further to get extended VM infos data
      # using the complete VM uri
      
      my $ext_data = decode_json $self->_http("GET",
                                               $vm->{uri},
                                               $self->{host},
                                               );
      
      push(@ret, Rex::Cloud::Ganeti::RAPI::VM->new(rapi => $self, data => $vm, extended_data => $ext_data));
   }

   return @ret;
}

sub _http {
   my $self = shift;
   my ($method, $url, $host) = @_;

   my $https = Net::HTTPS->new(Host => $host) || die $@;

   
   if($method eq "GET") {
     
     $https->write_request( GET => $url, 'User-Agent' => "Mozilla/5.0" );

     #my $encoded = encode_base64("$self->{user}:$self->{password}");
     #$http->add_req_header("Authorization", $encoded);
     Rex::Logger::debug("Will ask for $host$url request");
     my ($code, $mess, %h) = $https->read_response_headers;
     my $ret;
     while (1) {
        my $buf;
        my $n = $https->read_entity_body($buf, 1024);
        die "read failed: $!" unless defined $n;
        last unless $n;
        $ret.= $buf;
     }

     Rex::Logger::debug("Got $code for request");   
     
     Rex::Logger::debug("Got $ret for response");
     return $ret;
   }
   if($method eq "POST") {
    # $http->method($method);
    # $http->add_req_header('Content-type', 'application/json');
   }

   # FIXME: handle POST / PUT aswell 

}

1;