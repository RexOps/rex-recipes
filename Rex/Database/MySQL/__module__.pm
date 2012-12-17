#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: 
# LICENSE: Apache License 2.0
# 
# Simple Module to install MySQL on your Server.

package Rex::Database::MySQL;


use Rex -base;

# some package-wide variables

our %package = (
   Debian => "mysql-server",
   Ubuntu => "mysql-server",
   CentOS => "mysql-server",
   Mageia => "mysql",
);

our %service_name = (
   Debian => "mysql",
   Ubuntu => "mysql",
   CentOS => "mysqld",
   Mageia => "mysqld",
);

task "setup", sub {

   my $pkg     = $package{get_operating_system()};
   my $service = $service_name{get_operating_system()};

   # install mysql package
   update_package_db;
   install package => $pkg;

   # ensure that mysql is started
   service $service => "ensure" => "started";

};

task "start", sub {

   my $service = $service_name{get_operating_system()};
   service $service => "start";

};

task "stop", sub {

   my $service = $service_name{get_operating_system()};
   service $service => "stop";

};

task "restart", sub {

   my $service = $service_name{get_operating_system()};
   service $service => "restart";

};

task "reload", sub {

   my $service = $service_name{get_operating_system()};
   service $service => "reload";

};

1;

=pod

=head1 NAME

Rex::Database::MySQL - Module to install MySQL Server

=head1 USAGE

Put it in your I<Rexfile>

 # your tasks
 task "one", sub {};
 task "two", sub {};
    
 require Rex::Database::MySQL;

And call it:

 rex -H $host Database:MySQL:setup

Or, to use it as a library

 task "yourtask", sub {
    Rex::Database::MySQL::setup();
 };
   
 require Rex::Database::MySQL;

=head1 TASKS

=over 4

=item setup

This task will install mysql server.

=item start

This task will start the mysql daemon.

=item stop

This task will stop the mysql daemon.

=item restart

This task will restart the mysql daemon.

=item reload

This task will reload the mysql daemon.

=back

=cut

