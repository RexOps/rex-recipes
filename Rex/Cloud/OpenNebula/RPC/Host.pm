#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   

package Rex::Cloud::OpenNebula::RPC::Host;

use strict;
use warnings;

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

   return $self->{extended_data}->{NAME}->[0];
}

sub _get_info {
   my ($self) = @_;

   if(! exists $self->{extended_data}) {
      $self->{extended_data} = $self->{rpc}->_rpc("one.host.info", [ int => $self->id ]);
   }
}

1;
