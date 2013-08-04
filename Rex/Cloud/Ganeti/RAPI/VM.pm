package Rex::Cloud::Ganeti::RAPI::VM;

use strict;
use warnings;
use Data::Dumper;

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
                                    "/2/instances/". $self->name . "startup",
                                    $self->{rapi}->{host},
                                   );
   return $jobid;
}

sub stop {
   my $self = shift;

   my $jobid = $self->{rapi}->_http("PUT",
                                    "/2/instances/". $self->name . "shutdown",
                                    $self->{rapi}->{host},
                                   );
   return $jobid;
}


sub remove {
   my $self = shift;

   my $jobid = $self->{rapi}->_http("DELETE",
                                    "/2/instances/". $self->name,
                                    $self->{rapi}->{host},
                                   );
   return $jobid;
}

1;
