#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: 
# LICENSE: GPLv3
# 
# This is an example Module.

package Misc::Example;

use Rex -base;

task "prepare", sub {

   my ($param) = @_;

   say "You said: bar = " . $param->{bar};


};

1;

=pod

=head2 Example Module

This module is just an example.

=head2 USAGE

 rex -H $host Misc:Example:prepare --bar=baz

Or, to use it as a library

 use Misc::Example;
    
 task "prepare", sub {
    Misc::Example::prepare({
       bar => "baz"
    });
 };

