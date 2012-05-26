#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Lang::PHP::Module;
   
use strict;
use warnings;

use Rex -base;

task "setup", sub {

   my $param = shift;
   die("You have to set the module name.") unless $param->{name};

   my $pkg = sprintf($Rex::Lang::PHP::schema{get_operating_system()}, $param->{"name"});

   update_package_db;
   install package => $pkg;

};

task "uninstall", sub {

   my $param = shift;
   my $pkg = sprintf($Rex::Lang::PHP::schema{get_operating_system()}, $param->{"name"});

   remove package => $pkg;

};


1;

=pod

=head2 Install a PHP Module

This module installs PHP Modules on your system.

=head2 USAGE

 task name => sub {
    Rex::Lang::PHP::Module::setup({
       name => "mysql",
    });
      
    Rex::Lang::PHP::Module::remove({
       name => "mysql",
    });
 };

