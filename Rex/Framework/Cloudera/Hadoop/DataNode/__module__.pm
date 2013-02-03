#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com> 
# REQUIRES: Rex::Lang::Java, Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3 
# DESC:     Instantiated and configured a DataNode
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

   # determine cloudera-distribution version and set
   # os-specific package and service name
   my %package_name;
   my %service_name;

   if(is_file("/etc/apt/sources.list.d/cdh3.list")) {
      %package_name = %package_name_cdh3;
      %service_name = %service_name_cdh3;
   }
   elsif(is_file("/etc/apt/sources.list.d/cdh4.list")) {
      %package_name = %package_name_cdh4;
      %service_name = %service_name_cdh4;
   }
   else {
      die("Ensure that you added the Cloudera-Repository.");
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

Rex::Framework::Cloudera::Hadoop::DataNode - Instantiated and configured a DataNode

=head1 DESCRIPTION

A DataNode stores data in the Hadoop-File-System. A functional filesystem has more
than one DataNode, with data replicated across them. 

This Rex-Module instantiated and configured a DataNode.

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

This task will install the Hadoop NameNode-Service.

=back

=cut
