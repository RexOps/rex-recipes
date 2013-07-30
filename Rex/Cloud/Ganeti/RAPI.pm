package Rex::Cloud::Ganeti::RAPI;

use Data::Dumper;
use JSON;
use Net::HTTPS;
use MIME::Base64;

use Rex::Cloud::Ganeti::RAPI::Host;
use Rex::Cloud::Ganeti::RAPI::VM;
use Rex::Cloud::Ganeti::RAPI::OS;

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

   Rex::Logger::debug("get_vms : " . Dumper($data));

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

sub get_vm {
   my $self = shift;
   my %data = @_;
   
   my ($vm) = grep { $_->name eq $data{name} } $self->get_vms;
   
   return $vm; # it's an Rex::Cloud::Ganeti::RAPI::VM object
   
}

sub get_oses {
   my $self = shift;
   my $data = decode_json $self->_http("GET",
                                       "/2/os",
                                       #"/2/query/os?fields=name,variants", # too much hassle to parse!!!
                                       $self->{host},
                                       );

   
                                       
   Rex::Logger::debug(Dumper($data));
                                       
   my @ret = ();
   
   for my $os(@{$data}) {
      # $data is an array_ref, and i want hashrefs!
      my $tempdata = { name => $os };
      push(@ret, Rex::Cloud::Ganeti::RAPI::OS->new(rapi => $self, data => $tempdata));
   }
   
   return @ret;
}

sub create_vm {
   my $self = shift;
   
   #FIXME: 
}

sub _http {
   my $self = shift;
   my ($method, $url, $host) = @_;

   my $https = Net::HTTPS->new(Host => $host) || die $@;
   my $encoded = encode_base64("$self->{user}:$self->{password}");
   
   if($method eq "GET") {

     $https->write_request( GET           => $url,
                            'User-Agent'  => "Mozilla/5.0",
                            Authorization => "Basic $encoded",
                          );

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

     Rex::Logger::debug("Got status $code");
     Rex::Logger::debug("Got reply $ret");
     return $ret;
   }
   if($method eq "POST") {
    # $http->method($method);
    # $http->add_req_header('Content-type', 'application/json');
   }
   
   if($method eq "PUT") {
      $https->write_request(PUT           => $url,
                            'User-Agent'  => "Mozilla/5.0",
                            Authorization => "Basic $encoded",
                          );
      my ($code, $mess, %h) = $https->read_response_headers;
      my $ret;
      while (1) {
        my $buf;
        my $n = $https->read_entity_body($buf, 1024);
        die "read failed: $!" unless defined $n;
        last unless $n;
        $ret.= $buf;
     }
     Rex::Logger::debug("Got status $code");
     Rex::Logger::debug("Got reply $ret");
     return $ret; #should be a job id with this form: "123456"
   }
   # needs to handle DELETE too
}

1;
