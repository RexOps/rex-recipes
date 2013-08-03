package Rex::Cloud::Ganeti::RAPI;

use Data::Dumper;
use JSON;
use MIME::Base64;
use Net::HTTPS;


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

   # I first get the list of instances
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


### http://docs.ganeti.org/ganeti/2.5/html/rapi.html
### some info are found in doc/api.rst from ganeti
### man gnt-instance(8) also
sub create_vm {
   my ($self, %option) = @_;

   my %param;
   
   # minimum required to create an instance
   $param{ __version__   } = 1; # supported by newer ganeti installs
   $param{ mode          } = $option{mode};
   $param{ instance_name } = $option{name};
   $param{ disk_template } = $option{disk_template};
   $param{ disks         } = $option{disks};
   $param{ nics          } = $option{nics};
   
   $param{ hypervisor    } = $option{hypervisor} || "None";
   # should be like "osname+variant"
   $param{ os_type       } = $option{os} || $option{os_type} || "None";
   
   $param{ beparams      } = $option{beparams} || {};
   $param{ hvparams      } = $option{hv_params} || {};
   
   # FIXME: %option might contain keys that i'm not aware of yet.
   #   i need to pull those 'unnknown' options to $param
   
   my $json = encode_json \%param;
   #Rex::Logger::debug("json is" . Dumper($json));

   ### will return a jobid
   ### that could be a problem, because the VM needs some time to be created
   return $self->_http("POST",
                        "/2/instances",
                        $self->{host},
                        $json,
                       );
}

sub _http {
   my $self = shift;
   my ($method, $url, $host, $body) = @_;


   my $encoded = encode_base64("$self->{user}:$self->{password}");

   my $https = Net::HTTPS->new( Host          => $host,
                                'User-Agent'  => 'Mozilla/5.0',
                                Accept        => 'application/json',                                
                              ) || die $@;

   if ($method =~ /^(GET|PUT|DELETE)$/) {
      $https->write_request( $method       => $url,
                             Authorization => "Basic $encoded", );
   } elsif($method =~ /^POST$/) {
      Rex::Logger::debug( $https->format_request( $method        => $url,
                             'Content-type' => 'application/json',
                             Authorization => "Basic $encoded",
                             $body,
                           ) );
                           
      $https->write_request( $method        => $url,
                             'Content-type' => 'application/json', # must be Content-type, not Content-Type wtf
                             Authorization => "Basic $encoded",
                             $body,
                           );

    } else {
      die "$method isn't supported yet";
   }

   Rex::Logger::debug("Will ask for $host$url request");
   my ($code, $mess, %h) = $https->read_response_headers;
   
   # FIXME: Need to check for 5xx or 4xx return codes
   
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
