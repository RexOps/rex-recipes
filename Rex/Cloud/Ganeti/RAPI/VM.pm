package Rex::Cloud::Ganeti::RAPI::VM;

use strict;
use warnings;
use Data::Dumper;

use Rex::Cloud::Ganeti::RAPI::Job;

sub new {
   my $class = shift;
   my $proto = ref($class) || $class;
   my $self = { @_ };
   bless($self, $proto);
   return $self;
}

sub name {
   my $self = shift;

   #Rex::Logger::debug(Dumper($self));

   return $self->{data}->{name};
}

sub uri {
   my $self = shift;

   return $self->{data}->{uri};
}

sub status {
   my $self = shift;

   return $self->{data}->{status};

   ### should I update everytime I need the status ?
   ### yea, i think so.

}

sub resume {
   my $self = shift;

   my $jobid = $self->{rapi}->_http("PUT",
                                    "/2/instances/". $self->name . "/startup",
                                    $self->{rapi}->{host},
                                   );
   my $job = Rex::Cloud::Ganeti::RAPI::Job->new(rapi => $self->{rapi},
                                                data => { id => $jobid}
                                               );                                   
                                               
   return $job;
}

sub stop {
   my $self = shift;

   my $jobid = $self->{rapi}->_http("PUT",
                                    "/2/instances/". $self->name . "/shutdown",
                                    $self->{rapi}->{host},
                                   );

   my $job = Rex::Cloud::Ganeti::RAPI::Job->new(rapi => $self->{rapi},
                                                data => { id => $jobid},
                                               );
                                               
   Rex::Logger::debug("stop: ". Dumper($job));
   
   return $job;
}


sub remove {
   my $self = shift;

   my $jobid = $self->{rapi}->_http("DELETE",
                                    "/2/instances/". $self->name,
                                    $self->{rapi}->{host},
                                   );
   
   my $job = Rex::Cloud::Ganeti::RAPI::Job->new(rapi => $self->{rapi},
                                                data => { id => $jobid},
                                               );
                                   
   return $job;   
}

sub _get_info {
   my ($self, %option) = @_;

   my $refreshed_vm = $self->{rapi}->get_vm($self->name);

   $self->{data} = $refreshed_vm->{data};
   
}



1;
