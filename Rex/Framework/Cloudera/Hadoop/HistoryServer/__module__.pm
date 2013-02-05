#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com> 
# REQUIRES: Rex::Lang::Java
#           Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3 
# DESC:     Creates a Hadoop HistoryServer (MRv2)
#  
   
package Rex::Framework::Cloudera::Hadoop::HistoryServer;

use strict;
use warnings;

use Rex -base;

# define os-distribution specific package names
my %package_name = (
   Debian => "hadoop-mapreduce-historyserver",
   Ubuntu => "hadoop-mapreduce-historyserver",
);

# define os-distribution specific service names
my %service_name = (
   Debian => "hadoop-mapreduce-historyserver",
   Ubuntu => "hadoop-mapreduce-historyserver",
);

#
# TASK: setup
#
task "setup", sub {

   # install package
   update_package_db;
   install package => &get_package;

};

#
# TASK: start
#
task "start", sub {

   # ensure that service start at boot and running
   service &get_service => "ensure" => "started";

};

#
# TASK: stop
#
task "stop", sub {

   # stop service
   service &get_service => "stop";

};

#
# TASK: restart
#
task "restart", sub {

   # restart service
   service &get_service => "restart";

};

#
# FUNCTION: get_package
#
sub get_package {

   # defining package based on os-distribution and return it
   my $package = $package_name{get_operating_system()};

   die("Your Linux-Distribution is not supported by this Rex-Module.") unless $package;

   return $package;

};

#
# FUNCTION: get_service
#
sub get_service {

   # defining service based on os-distribution and return it
   my $service = $service_name{get_operating_system()};

   die("Your Linux-Distribution is not supported by this Rex-Module.") unless $service;   

   return $service;

};

1;

=pod

=head1 NAME

Rex::Framework::Cloudera::Hadoop::HistoryServer - Creates a Hadoop HistoryServer (MRv2)

=head1 DESCRIPTION

The History server keeps records of the different activities being performed
on a Hadoop cluster.

This Rex-Module creates a Hadoop HistoryServer (MRv2).

=head1 USAGE

Put it in your I<Rexfile>

 require Rex::Framework::Cloudera::Hadoop::HistoryServer;
  
 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::HistoryServer::setup();
 };

And call it:

 rex -H $host yourtask

=head1 TASKS

=over 4

=item setup

This task will install the Hadoop the Hadoop HistoryServer.

=item start

This task will start the Hadoop HistoryServer service and ensure that the service start at boot.

=item stop

This task will stop the Hadoop HistoryServer service.

=item restart

This task will restart the Hadoop HistoryServer service.

=back

=cut
