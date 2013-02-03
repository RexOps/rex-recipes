#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com>
# REQUIRES: Rex::Lang::Java, Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3
# DESC:     Instantiated and configured a JobTracker node (MRv1 and MRv2)
#

package Rex::Framework::Cloudera::Hadoop::JobTracker;

use strict;
use warnings;

use Rex -base;

# define os-distribution specific package names
my %package_name_cdh3 = (
   Debian => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-jobtracker",
   Ubuntu => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-jobtracker",
);

my %package_name_mrv1_cdh4 = (
   Debian => "hadoop-0.20-mapreduce-jobtracker",
   Ubuntu => "hadoop-0.20-mapreduce-jobtracker",
);

my %package_name_mrv2_cdh4 = (
   Debian => "hadoop-yarn-resourcemanager",
   Ubuntu => "hadoop-yarn-resourcemanager",
);

# define os-distribution specific service names
my %service_name_cdh3 = (
   Debian => "hadoop-0.20-jobtracker",
   Ubuntu => "hadoop-0.20-jobtracker",
);

my %service_name_mrv1_cdh4 = (
   Debian => "hadoop-0.20-mapreduce-jobtracker",
   Ubuntu => "hadoop-0.20-mapreduce-jobtracker",
);

my %service_name_mrv2_cdh4 = (
   Debian => "hadoop-yarn-resourcemanager",
   Ubuntu => "hadoop-yarn-resourcemanager",
);

#
# TASK: setup
#
task "setup", sub {

   my $param = shift;

   # determine cloudera-distribution version and set
   # os-specific package and service name
   my %package_name;
   my %service_name;

   if($param->{"mr_version"} eq "mrv1") {
      if(is_file("/etc/apt/sources.list.d/cdh3.list")) {
         %package_name = %package_name_cdh3;
         %service_name = %service_name_cdh3;
      }
      elsif(is_file("/etc/apt/sources.list.d/cdh4.list")) {
         %package_name = %package_name_mrv1_cdh4;
         %service_name = %service_name_mrv1_cdh4;
      }
      else {
         die("Ensure that you added the Cloudera-Repository.");
      }
   }
   elsif($param->{"mr_version"} eq "mrv2") {
      if(is_file("/etc/apt/sources.list.d/cdh3.list")) {
         die("MapReduce Version 2 is not supported by CDH3.");
      }
      elsif(is_file("/etc/apt/sources.list.d/cdh4.list")) {
         %package_name = %package_name_mrv2_cdh4;
         %service_name = %service_name_mrv2_cdh4;
      }
      else {
         die("Ensure that you added the Cloudera-Repository.");
      }
   }

   # defining package and service based on os-distribution
   my $package = $package_name{get_operating_system()};
   my $service = $service_name{get_operating_system()};

   # install package
   update_package_db;
   install package => $package;

   # ensure that service start at boot
   service $service => "ensure" => "started";

};

1;

=pod

=head1 NAME

Rex::Framework::Cloudera::Hadoop::JobTracker - Instantiated and configured a JobTracker node (MRv1 and MRv2)

=head1 DESCRIPTION

The JobTracker is the service within Hadoop that farms out MapReduce tasks
to specific nodes in the cluster, ideally the nodes that have the data, or
at least are in the same rack.

This Rex-Module instantiated and configured a JobTracker node (MRv1 and MRv2).

=head1 USAGE

Put it in your I<Rexfile>

 require Rex::Framework::Cloudera::Hadoop::JobTracker;
  
 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::JobTracker::setup({
       mr_version => "mrv1",
    });
 };

And call it:

 rex -H $host yourtask

=head1 TASKS

=over 4

=item setup

This task will install the Hadoop JobTracker-Service.

=over 4

=item mr_version

Define the MapReduce Version of the JobTracker-Service. Valid parameters
are "mrv1" (MapReduce Version 1) or "mrv2" (MapReduce Version 2).

=back

 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::JobTracker::setup({
       mr_version => "mrv1",
    });
 };

=back

=cut
