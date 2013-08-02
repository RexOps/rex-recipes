#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Ext::ParamValidate;

use strict;
use warnings;

use Filter::Simple;
require Exporter;
use base qw(Exporter);
use vars qw (@EXPORT);

@EXPORT = qw(validate);

FILTER {
   s/validate (\$[a-zA-Z0-9_]+)/$1 \/\/= {} ; validate $1/gms;
};


sub validate {
   my ($param, %opt) = @_;

   for my $key (keys %opt) {
      my $val = $param->{$key};
      my $reg = $opt{$key};

      if(ref $reg eq "HASH") {
         my $opt = 0;
         if( exists $reg->{optional} ) {
            $opt = 1;
         }

         if( exists $reg->{default} && ! exists $param->{$key} ) {
            $param->{$key} = $reg->{default};

            next;
         }

         if( exists $reg->{type} ) {
            my $type_class = "Rex::Ext::ParamValidate::Type::" . lc($reg->{type});
            eval "use $type_class;";
            if($@) {
               die("Invalid type given.");
            }

            my $type = $type_class->new;
            eval {
               $param->{$key} = $type->validate($param->{$key});
            } or do {
               Rex::Logger::info("Error validating input. $key must be of type $reg->{type}");
               die("Error validating input. $key must be of type $reg->{type}");
            };

            next;
         }

         if( exists $reg->{match} ) {
            if( ! defined $val && $opt == 1) {
               # param is optional and empty, just skip
               next;
            }

            if( $val !~ $reg->{match} ) {
               Rex::Logger::info("Error validating input. $key must be of type $reg");
               die("Error validating input. $key must be of type $reg");

               next;
            }
         }

         if( exists $reg->{cb} & ref($reg->{cb}) eq "CODE" ) {
            if( ! defined $val && $opt == 1) {
               # param is optional and empty, just skip
               next;
            }

            my $callback = $reg->{cb};
            $param->{$key} = $callback->($val);

            next;
         }

      }
      else {
         if( ! defined $val ) {
            Rex::Logger::info("Error validating input. $key must be of type $reg");
            die("Error validating input. $key must be of type $reg");
         }

         if( $val !~ $reg ) {
            Rex::Logger::info("Error validating input. $key must be of type $reg");
            die("Error validating input. $key must be of type $reg");
         }
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
     
    validate $param,
       name => qr{^[a-z]+$},
       age  => {
          default => 30, 
       },  
       city => {
          cb => sub {
             my ($val) = @_; 
             print "got: $val\n";
             return "checked: $val";
          },  
       },  
       road => {
          optional => 1,
       },  
       birth => {
          optional => 1,
          default => 1970,
       };
 };

=cut

1;
