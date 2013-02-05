#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com> 
# REQUIRES: Rex::Lang::Java
#           Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3 
# DESC:     Creates a Hadoop DataNode
#  
   
package Rex::Framework::Cloudera::Hadoop::DataNode;

use strict;
use warnings;

use Rex -base;

# define os-distribution specific package names
my %package_name_cdh3 = (
   Debian => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-datanode",
   Ubuntu => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-datanode",
);

my %package_name_cdh4 = (
   Debian => "hadoop-hdfs-datanode",
   Ubuntu => "hadoop-hdfs-datanode",
);

# define os-distribution specific service names
my %service_name_cdh3 = (
   Debian => "hadoop-0.20-datanode",
   Ubuntu => "hadoop-0.20-datanode",
);

my %service_name_cdh4 = (
   Debian => "hadoop-hdfs-datanode",
   Ubuntu => "hadoop-hdfs-datanode",
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

   # determine cloudera-distribution version
   # and set specific package name
   my %package_name;
   my $cdh_version = Rex::Framework::Cloudera::PkgRepository::get_cdh_version();

   if($cdh_version eq "cdh3") {
      %package_name = %package_name_cdh3;
   }
   elsif($cdh_version eq "cdh4") {
      %package_name = %package_name_cdh4;
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

   # determine cloudera-distribution version
   # and set specific service name
   my %service_name;
   my $cdh_version = Rex::Framework::Cloudera::PkgRepository::get_cdh_version();

   if($cdh_version eq "cdh3") {
      %service_name = %service_name_cdh3;
   }
   elsif($cdh_version eq "cdh4") {
      %service_name = %service_name_cdh4;
   }

   # defining service based on os-distribution and return it
   my $service = $service_name{get_operating_system()};

   die("Your Linux-Distribution is not supported by this Rex-Module.") unless $service;

   return $service;

};

1;

=pod

=head1 NAME

Rex::Framework::Cloudera::Hadoop::DataNode - Creates a Hadoop DataNode

=head1 DESCRIPTION

A DataNode stores data in the Hadoop-File-System. A functional filesystem has more
than one DataNode, with data replicated across them. 

This Rex-Module creates a Hadoop DataNode.

=head1 USAGE

Put it in your I<Rexfile>

 require Rex::Framework::Cloudera::Hadoop::DataNode;
  
 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::DataNode::setup();
 };

And call it:

 rex -H $host yourtask

=head1 TASKS

=over 4

=item setup

This task will install the Hadoop DataNode.

=item start

This task will start the Hadoop DataNode service and ensure that the service start at boot.

=item stop

This task will stop the Hadoop DataNode service.

=item restart

This task will restart the Hadoop DataNode service.

=back

=cut
