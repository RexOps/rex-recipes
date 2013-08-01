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
   my $data = decode_json $self->_http('GET',
                                       '/2/instances?bulk=1',
                                       $self->{host},
                                       );

   Rex::Logger::debug("get_vms : " . Dumper($data));

   my @ret = ();

   for my $vm (@{ $data }) {
      push(@ret, Rex::Cloud::Ganeti::RAPI::VM->new(rapi => $self, data => $vm));
   }

   return @ret;
}

sub get_vm {
   my ($self, $vm_name) = @_;

   my ($vm) = grep { $_->name eq $vm_name } $self->get_vms;

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
   my ($self, %data) = @_;

   

   #FIXME:
}

sub _http {
   my $self = shift;
   my ($method, $url, $host) = @_;

   my $https = Net::HTTPS->new( Host          => $host,
                                'User-Agent'  => 'Mozilla/5.0',
                                Authorization => "Basic $encoded",
                              ) || die $@;
   my $encoded = encode_base64("$self->{user}:$self->{password}");

   if ($method =~ /^(GET|PUT|DELETE)$/) {
      $https->write_request( $method => $url );
   } elsif($method =~ /^POST$/) {
      $https->write_request( $method        => $url,
                             'Content-type' => 'application/json',
                           );
    } else {
      die "$method isn't implemented";
   }

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

   Rex::Logger::debug("Got status $code and reply $ret");
   return $ret; #most of the time, should be a job id with this form: "123456"

}

1;
