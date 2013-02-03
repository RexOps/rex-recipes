#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com> 
# REQUIRES: Rex::Lang::Java, Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3 
# DESC:     Instantiated and configured a NameNode (primary and secondary)
#  

package Rex::Framework::Cloudera::Hadoop::NameNode;

use strict;
use warnings;

use Rex -base;

# define os-distribution specific package names
my %package_name_primary_namenode_cdh3 = (
   Debian => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-namenode",
   Ubuntu => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-namenode",
);

my %package_name_secondary_namenode_cdh3 = (
   Debian => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-secondarynamenode",
   Ubuntu => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-secondarynamenode",
);

my %package_name_primary_namenode_cdh4 = (
   Debian => "hadoop-hdfs-namenode",
   Ubuntu => "hadoop-hdfs-namenode",
);

my %package_name_secondary_namenode_cdh4 = (
   Debian => "hadoop-hdfs-secondarynamenode",
   Ubuntu => "hadoop-hdfs-secondarynamenode",
);

# define os-distribution specific service names
my %service_name_primary_namenode_cdh3 = (
   Debian => "hadoop-0.20-namenode",
   Ubuntu => "hadoop-0.20-namenode",
);

my %service_name_secondary_namenode_cdh3 = (
   Debian => "hadoop-0.20-secondarynamenode",
   Ubuntu => "hadoop-0.20-secondarynamenode",
);

my %service_name_primary_namenode_cdh4 = (
   Debian => "hadoop-hdfs-namenode",
   Ubuntu => "hadoop-hdfs-namenode",
);

my %service_name_secondary_namenode_cdh4 = (
   Debian => "hadoop-hdfs-secondarynamenode",
   Ubuntu => "hadoop-hdfs-secondarynamenode",
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

   if($param->{"namenode_role"} eq "primary") {
      if(is_file("/etc/apt/sources.list.d/cdh3.list")) {
         %package_name = %package_name_primary_namenode_cdh3;
         %service_name = %service_name_primary_namenode_cdh3;
      }
      elsif(is_file("/etc/apt/sources.list.d/cdh4.list")) {
         %package_name = %package_name_primary_namenode_cdh4;
         %service_name = %service_name_primary_namenode_cdh4;
      }
      else {
         die("Ensure that you added the Cloudera-Repository.");
      }
   }
   elsif($param->{"namenode_role"} eq "secondary") {
      if(is_file("/etc/apt/sources.list.d/cdh3.list")) {
         %package_name = %package_name_secondary_namenode_cdh3;
         %service_name = %service_name_secondary_namenode_cdh3;
      }
      elsif(is_file("/etc/apt/sources.list.d/cdh4.list")) {
         %package_name = %package_name_secondary_namenode_cdh4;
         %service_name = %service_name_secondary_namenode_cdh4;
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

Rex::Framework::Cloudera::Hadoop::NameNode - Instantiated and configured a NameNode (primary and secondary)

=head1 DESCRIPTION

The NameNode is the centerpiece of an HDFS file system. It keeps the directory
tree of all files in the file system, and tracks where across the cluster the
file data is kept. It does not store the data of these files itself.
The NameNode is a Single Point of Failure for the HDFS Cluster. HDFS is not
currently a High Availability system. When the NameNode goes down, the file
system goes offline. There is an optional SecondaryNameNode that can be hosted
on a separate machine. It only creates checkpoints of the namespace by merging
the edits file into the fsimage file and does not provide any real redundancy.

This Rex-Module instantiated and configured a NameNode (primary and secondary).

=head1 USAGE

Put it in your I<Rexfile>

 require Rex::Framework::Cloudera::Hadoop::NameNode;
  
 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::NameNode::setup({
       namenode_role => "primary",
    });
 };

And call it:

 rex -H $host yourtask

=head1 TASKS

=over 4

=item setup

This task will install the Hadoop NameNode-Service.

=over 4

=item namenode_role

Define the primary or secondary role ofe the NameNode-Service.

=back

 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::NameNode::setup({
       namenode_role => "primary",
    });
 };

=back

=cut
