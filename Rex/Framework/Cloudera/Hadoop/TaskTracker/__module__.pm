#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com>
# REQUIRES: Rex::Lang::Java
#           Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3
# DESC:     Creates a Hadoop TaskTracker node (MRv1 and MRv2)
#

package Rex::Framework::Cloudera::Hadoop::TaskTracker;

use strict;
use warnings;

use Rex -base;

# define os-distribution specific package names
my %package_name_cdh3 = (
   Debian => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-tasktracker",
   Ubuntu => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-tasktracker",
);

my %package_name_mrv1_cdh4 = (
   Debian => "hadoop-0.20-mapreduce-tasktracker",
   Ubuntu => "hadoop-0.20-mapreduce-tasktracker",
);

my %package_name_mrv2_cdh4 = (
   Debian => "hadoop-mapreduce hadoop-yarn-nodemanager",
   Ubuntu => "hadoop-mapreduce hadoop-yarn-nodemanager",
);

# define os-distribution specific service names
my %service_name_cdh3 = (
   Debian => "hadoop-0.20-tasktracker",
   Ubuntu => "hadoop-0.20-tasktracker",
);

my %service_name_mrv1_cdh4 = (
   Debian => "hadoop-0.20-mapreduce-tasktracker",
   Ubuntu => "hadoop-0.20-mapreduce-tasktracker",
);

my %service_name_mrv2_cdh4 = (
   Debian => "hadoop-yarn-nodemanager",
   Ubuntu => "hadoop-yarn-nodemanager",
);

#
# TASK: setup
#
task "setup", sub {

   my $param = shift;

   # install package
   update_package_db;
   install package => &get_package($param);

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

   my $param = shift;

   # determine cloudera-distribution version and set
   # specific package name addicted by map-reduce version
   my %package_name;
   my $cdh_version = Rex::Framework::Cloudera::PkgRepository::get_cdh_version();

   if($param->{"mr_version"} eq "mrv1") {
      if($cdh_version eq "cdh3") {
         %package_name = %package_name_cdh3;
      }
      elsif($cdh_version eq "cdh4") {
         %package_name = %package_name_mrv1_cdh4;
      }
   }
   elsif($param->{"mr_version"} eq "mrv2") {
      if($cdh_version eq "cdh3") {
         die("MapReduce Version 2 is not supported by CDH3.");
      }
      elsif($cdh_version eq "cdh4") {
         %package_name = %package_name_mrv2_cdh4;
      }
   }
   else {
      die("Valid parameters are mrv1 (MapReduce Version 1) or mrv2 (MapReduce Version 2).");
   }

   # defining package based on os-distribution and return it
   my $package = $package_name{get_operating_system()};

   die("Your Linux-Distribution is not supported by this Rex-Module.") unless $package;

   return $package;

};

#
# FUNCTION: get_service
#
sub get_service {

   # determine cloudera-distribution version and set
   # specific package name addicted by map-reduce version
   my %service_name;
   my $cdh_version = Rex::Framework::Cloudera::PkgRepository::get_cdh_version();

   if(is_installed(&get_package({mr_version => "mrv1"}))) {
      if($cdh_version eq "cdh3") {
         %service_name = %service_name_cdh3;
      }
      elsif($cdh_version eq "cdh4") {
         %service_name = %service_name_mrv1_cdh4;
      }
   }
   elsif(is_installed(&get_package({mr_version => "mrv2"}))) {
      %service_name = %service_name_mrv2_cdh4;
   }
   else {
      die("The Hadoop TaskTracker is not installed");
   }

   # defining service based on os-distribution and return it
   my $service = $service_name{get_operating_system()};

   die("Your Linux-Distribution is not supported by this Rex-Module.") unless $service;

   return $service;

};

1;

=pod

=head1 NAME

Rex::Framework::Cloudera::Hadoop::TaskTracker - Creates a Hadoop TaskTracker node (MRv1 and MRv2)

=head1 DESCRIPTION

A TaskTracker is a node in the cluster that accepts tasks
- Map, Reduce and Shuffle operations - from a JobTracker. 

This Rex-Module creates a Hadoop TaskTracker node (MRv1 and MRv2).

=head1 USAGE

Put it in your I<Rexfile>

 require Rex::Framework::Cloudera::Hadoop::TaskTracker;
  
 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::TaskTracker::setup({
       mr_version => "mrv1",
    });
 };

And call it:

 rex -H $host yourtask

=head1 TASKS

=over 4

=item setup

This task will install the Hadoop TaskTracker node.

=over 4

=item mr_version

Define the MapReduce Version of the TaskTracker-Service. Valid parameters
are "mrv1" (MapReduce Version 1) or "mrv2" (MapReduce Version 2).

=back

 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::TaskTracker::setup({
       mr_version => "mrv1",
    });
 };

=item start

This task will start the Hadoop TaskTracker service and ensure that the service start at boot.

=item stop

This task will stop the Hadoop TaskTracker service.

=item restart

This task will restart the Hadoop TaskTracker service.

=back

=cut
