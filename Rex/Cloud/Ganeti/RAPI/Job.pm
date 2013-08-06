package Rex::Cloud::Ganeti::RAPI::Job;

use strict;
use warnings;
use Data::Dumper;

sub new {
   my $class = shift;
   my $proto = ref($class) || $class;
   my $self = { @_ };
   #Rex::Logger::debug("my job is : " . Dumper($self));
   
   # I strip everything but the jobid number
   # because it is probably raw HTTP body text at the moment
   ($self->{data}{id}) = ($self->{data}{id} =~ /(\d+)/);
   
   ### FIXME add some checks to make sure an "id" is given.
   
   Rex::Logger::debug("my job is : " . Dumper($self));
      
   bless($self, $proto);
   return $self;
}


sub status {
   my $self = shift;
   
   $self->_get_info;
   # FIXME : Add some checks to make sure the job is still here
   #         if (exists $self->{data}->{status};)
   #         set to "error" to stop the mess.
   return $self->{data}->{status};
}

sub id {

  my $self = shift;
  
  return $self->{data}->{id};
   
}

sub _get_info {
   my $self = shift;

   my $refreshed_job = $self->{rapi}->get_job($self->id);

   $self->{data} = $refreshed_job->{data};
   
   Rex::Logger::debug("_get_info : ". Dumper($self))
   
}
1;
