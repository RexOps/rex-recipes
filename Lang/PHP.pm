#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: 
# LICENSE: GPLv3
# 
# Simple Module to install PHP on your Server.

package Lang::PHP;


use Rex -base;

# some package-wide variables

our %schema = (
   Debian => 'php5-%s',
   Ubuntu => 'php5-%s',
   CentOS => 'php-%s',
   Mageia => 'php-%s',
);

our %package = (
   Debian => 'php5',
   Ubuntu => 'php5',
   CentOS => 'php',
   Mageia => 'php-cli',
);

our %pear_schema = (
   Debian => 'php-%s',
   Ubuntu => 'php-%s',
   CentOS => 'php-pear-%s',
   Mageia => 'php-pear-%s',
);

our %pecl_schema = (
   Debian => 'php5-%s',
   Ubuntu => 'php5-%s',
   CentOS => 'php-pecl-%s',
   Mageia => 'php-%s',
);

task "setup", sub {

   my $pkg     = $package{get_operating_system()};

   # install php package
   update_package_db;
   install package => $pkg;

};

1;

=pod

=head2 Module to install PHP

This module installs PHP.

=head2 USAGE

Put it in your I<Rexfile>

 # your tasks
 task "one", sub {};
 task "two", sub {};
    
 require Lang::PHP;

And call it:

 rex -H $host Lang:PHP:setup

Or, to use it as a library

 task "yourtask", sub {
    Lang::PHP::setup();
 };
   
 require Lang::PHP;

=head2 TASKS

=over 4

=item setup

This task will install PHP.

=back

=cut

