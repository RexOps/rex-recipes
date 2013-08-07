package Rex::Cloud::Ganeti::RAPI;

use Data::Dumper;
use JSON;
use MIME::Base64;
use Net::HTTPS;

use Rex::Cloud::Ganeti::RAPI::Host;
use Rex::Cloud::Ganeti::RAPI::Job;
use Rex::Cloud::Ganeti::RAPI::OS;
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

sub get_job {
   my ($self, $id) = @_;
   
   my $data = decode_json $self->_http("GET",
                                       "/2/jobs/". $id,
                                       $self->{host},
                                      );
   Rex::Logger::debug("get_job ". Dumper($data));                                      
   return Rex::Cloud::Ganeti::RAPI::Job->new(rapi => $self, data => $data);
   
}

sub get_oses {
   my $self = shift;
   my $data = decode_json $self->_http("GET",
                                       "/2/os",
                                       #"/2/query/os?fields=name,variants", # too much hassle to parse!!!
                                       $self->{host},
                                       );

   Rex::Logger::debug("get_oses ". Dumper($data));

   my @ret = ();

   for my $os(@{$data}) {
      # $data is an array_ref, and i want hashrefs!
      my $tempdata = { name => $os };
      push(@ret, Rex::Cloud::Ganeti::RAPI::OS->new(rapi => $self, data => $tempdata));
   }

   return @ret;
}


### create_vm should return a Rex::Cloud::Ganeti::RAPI::Job
sub create_vm {
   my ($self, %option) = @_;

   my $json = encode_json \%option;
   Rex::Logger::debug("create_vm " . Dumper($json));

   my $jobid =  $self->_http("POST",
                             "/2/instances",
                             $self->{host},
                             $json,
                            );
   ### $jobid content will get cleaned in the next statement
   my $job = Rex::Cloud::Ganeti::RAPI::Job->new(rapi => $self,
                                                data => { id => $jobid},
                                               );
                                               
   return $job;
}

sub _http {
   my $self = shift;
   my ($method, $url, $host, $body) = @_;

   if(defined $self->{user}) {
      die("Password not specified") if ( ! defined $self->{password});
   } elsif (defined $self->{password} ) {
      die("Specified password without username");
   }
   
   my $encoded = encode_base64("$self->{user}:$self->{password}");

   my $https = Net::HTTPS->new( Host          => $host,
                                'User-Agent'  => 'Rex RAPI Client',
                                Accept        => 'application/json',                                
                              ) || die $@;

   if ($method =~ /^(GET|PUT|DELETE)$/) {
      Rex::Logger::debug($https->format_request( $method       => $url,
                             Authorization => "Basic $encoded", ));
      $https->write_request( $method       => $url,
                             Authorization => "Basic $encoded", );
   } elsif($method =~ /^POST$/) {
      Rex::Logger::debug( $https->format_request( $method        => $url,
                                                  'Content-Type' => 'application/json',
                                                  Authorization  => "Basic $encoded",
                                                  $body )
                        );
                           
      $https->write_request( $method        => $url,
                             'Content-Type' => 'application/json',
                             Authorization  => "Basic $encoded",
                             $body,
                           );

    } else {
      die "$method isn't supported yet";
   }

   Rex::Logger::debug("Will ask for $host$url request");
   my ($code, $mess, %h) = $https->read_response_headers;
   
   if($code =~ /^[45]/) {
      die "Error $code : $mess";
   }
   
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
