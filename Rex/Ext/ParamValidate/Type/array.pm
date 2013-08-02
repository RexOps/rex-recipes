#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Ext::ParamValidate::Type::array;

use strict;
use warnings;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub validate {
   my ($self, $var) = @_;

   if(ref $var eq "ARRAY") {
      return $var;
   }

   return undef;
}

1;
