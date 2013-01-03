#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
# !no_doc!
   
package Rex::Cloud::OpenNebula::RPC::VM::NIC;

use strict;
use warnings;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub ip {
   my ($self) = @_;
   return $self->{data}->{IP}->[0];
}

sub mac {
   my ($self) = @_;
   return $self->{data}->{MAC}->[0];
}

sub bridge {
   my ($self) = @_;
   return $self->{data}->{BRIDGE}->[0];
}

# returns 0 if no vlan is present
sub has_vlan {
   my ($self) = @_;
   return $self->{data}->{VLAN}->[0] eq "NO" ? 0 : 1;
}

1;
