#
# (c) Joris De Pooter <jorisd@gmail.com>
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

# Some of the code is based on Rex::Cloud::OpenNebula

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
   
   $self->_get_info;
   
   return $self->{data}->{status};

}

sub ip {
   my $self = shift;
   
   return $self->name; ### It's not common with Ganeti to manage an VM with its IP address.
                       ### Because an instance name should always resolve.
                       ### http://docs.ganeti.org/ganeti/2.5/html/admin.html#adding-an-instance
                       ### Returning a hostname shouldn't be a problem with 'get_cloud_instances_as_group'
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
                                               
   #Rex::Logger::debug("stop: ". Dumper($job));
   
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

sub arch {

   my $self = shift;
   
   return "UNSUPPORTED"; # at the moment...
   
}

sub _get_info {
   my ($self, %option) = @_;

   my $refreshed_vm = $self->{rapi}->get_vm($self->name);

   $self->{data} = $refreshed_vm->{data};
   
}



1;
