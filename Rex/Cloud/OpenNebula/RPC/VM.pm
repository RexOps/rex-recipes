#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   

package Rex::Cloud::OpenNebula::RPC::VM;

use strict;
use warnings;

use Rex::Cloud::OpenNebula::RPC::VM::NIC;

use Data::Dumper;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub id {
   my ($self) = @_;
   return $self->{data}->{ID}->[0];
}

sub name {
   my ($self) = @_;
   $self->_get_info();

   return $self->{extended_data}->{TEMPLATE}->[0]->{NAME}->[0];
}

sub nics {
   my ($self) = @_;
   $self->_get_info();

   my @ret = ();

   for my $nic (@{ $self->{extended_data}->{TEMPLATE}->[0]->{NIC} }) {
      push(@ret, Rex::Cloud::OpenNebula::RPC::VM::NIC->new(data => $nic));
   }

   return @ret;
}

sub shutdown {
   my ($self) = @_;
   $self->{rpc}->_rpc("one.vm.action",
                        [ string => "shutdown" ],
                        [ int => $self->id ],
                     );
}

sub reboot {
   my ($self) = @_;
   $self->{rpc}->_rpc("one.vm.action",
                        [ string => "reboot" ],
                        [ int => $self->id ],
                     );
}

sub suspend {
   my ($self) = @_;
   $self->{rpc}->_rpc("one.vm.action",
                        [ string => "suspend" ],
                        [ int => $self->id ],
                     );
}

sub resume {
   my ($self) = @_;
   $self->{rpc}->_rpc("one.vm.action",
                        [ string => "resume" ],
                        [ int => $self->id ],
                     );
}

sub restart {
   my ($self) = @_;
   $self->{rpc}->_rpc("one.vm.action",
                        [ string => "restart" ],
                        [ int => $self->id ],
                     );
}

sub stop {
   my ($self) = @_;
   $self->{rpc}->_rpc("one.vm.action",
                        [ string => "stop" ],
                        [ int => $self->id ],
                     );
}



sub _get_info {
   my ($self) = @_;

   if(! exists $self->{extended_data}) {
      $self->{extended_data} = $self->{rpc}->_rpc("one.vm.info", [ int => $self->id ]);
   }
}

1;
