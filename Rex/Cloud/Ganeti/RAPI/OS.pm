#
# (c) Joris De Pooter <jorisd@gmail.com>
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

# Some of the code is based on Rex::Cloud::OpenNebula

package Rex::Cloud::Ganeti::RAPI::OS;

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
   my ($osname, undef) = split('\+', $self->{data}->{name});
   
   return $osname;
}

sub variant {
   my $self = shift;
   my (undef, $variant) = split('\+', $self->{data}->{name});
   
   return $variant;
}

1;
