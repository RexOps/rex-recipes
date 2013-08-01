#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Ext::ParamValidate::Type::ip;

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

   # not really rfc conform, but okay
   if($var =~ m/^\d+\.\d+\.\d+\.\d+$/) {
      return $var;
   }

   return undef;
}

1;
