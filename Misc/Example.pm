#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: 
# LICENSE: Apache License 2.0
# 
# This is an example Module.

package Misc::Example;

use Rex -base;

task "prepare", sub {

   my ($param) = @_;
   if(! exists $param->{bar}) {
      die("Please use --bar=foo\n");
   }

   say "You said: bar = " . $param->{bar};
   print template("Example/files/test.txt");
   

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

