#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Ext::ParamValidate;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
use vars qw (@EXPORT);

@EXPORT = qw(validate);


sub validate {
   my ($param, %opt) = @_;

   for my $key (keys %opt) {
      my $val = $param->{$key};
      my $reg = $opt{$key};

      if( $val !~ $reg ) {
         Rex::Logger::info("Error validating input. $key must be of type $reg");
         die("Error validating input. $key must be of type $reg");
      }
   }
}

=pod

=head1 NAME

Rex::Ext::ParamValidate - Validate task parameter.

This extension gives you a validate() function to validate task parameters.

If a condition failed, the function will die().

=head1 SYNOPSIS

 use Rex::Ext::ParamValidate;
   
 task "prepare", sub {
    my $param = shift;
    
    validate $param,
      name   => qr{^[a-zA-Z0-9_]+$},
      url    => qr{^http://.*$},
      number => qr{^\d+$};
 };

=cut

1;
