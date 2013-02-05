#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com> 
# REQUIRES: Rex::Lang::Java
#           Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3 
# DESC:     Creates a Hadoop NameNode (primary and secondary)
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

   # install package
   update_package_db;
   install package => &get_package($param);

};

#
# TASK: format_hdfs
#
task "format_hdfs", sub {

   # format the name-node if is not allready formatted
   if(is_dir("/var/lib/hadoop-hdfs/cache/hdfs")) {
      say "The Hadoop Filesystem is already formatted.";
   }
   else {
      run "sudo -u hdfs hdfs namenode -format";
   }

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
   # specific package name addicted by name node role
   my %package_name;
   my $cdh_version = Rex::Framework::Cloudera::PkgRepository::get_cdh_version();

   if($param->{"namenode_role"} eq "primary") {
      if($cdh_version eq "cdh3") {
         %package_name = %package_name_primary_namenode_cdh3;
      }
      elsif($cdh_version eq "cdh4") {
         %package_name = %package_name_primary_namenode_cdh4;
      }
   }
   elsif($param->{"namenode_role"} eq "secondary") {
      if($cdh_version eq "cdh3") {
         %package_name = %package_name_secondary_namenode_cdh3;
      }
      elsif($cdh_version eq "cdh4") {
         %package_name = %package_name_secondary_namenode_cdh4;
      }
   }
   else {
      die("Valid parameters are primary (Primary NameNode) or secondary (Secondary NameNode).");
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
   # specific package name addicted by name-node role
   my %service_name;
   my $cdh_version = Rex::Framework::Cloudera::PkgRepository::get_cdh_version();

   if(is_installed(&get_package({namenode_role => "primary"}))) {
      if($cdh_version eq "cdh3") {
         %service_name = %service_name_primary_namenode_cdh3;
      }
      elsif($cdh_version eq "cdh4") {
         %service_name = %service_name_primary_namenode_cdh3;
      }
   }
   elsif(is_installed(&get_package({namenode_role => "secondary"}))) {
      if($cdh_version eq "cdh3") {
         %service_name = %service_name_secondary_namenode_cdh3;
      }
      elsif($cdh_version eq "cdh4") {
         %service_name = %service_name_secondary_namenode_cdh4;
      }
   }
   else {
      die("The Hadoop NameNode is not installed.");
   }

   # defining service based on os-distribution and return it
   my $service = $service_name{get_operating_system()};

   die("Your Linux-Distribution is not supported by this Rex-Module.") unless $service;

   return $service;

};

1;

=pod

=head1 NAME

Rex::Framework::Cloudera::Hadoop::NameNode - Creates a Hadoop NameNode (primary and secondary)

=head1 DESCRIPTION

The NameNode is the centerpiece of an HDFS file system. It keeps the directory
tree of all files in the file system, and tracks where across the cluster the
file data is kept. It does not store the data of these files itself.

This Rex-Module creates a Hadoop NameNode (primary and secondary).

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

This task will install the Hadoop NameNode.

=over 4

=item namenode_role

Define the primary or secondary role ofe the NameNode-Service. Valid parameters
are "primary" (Primary NameNode) or "secondary" (Secondary NameNode).

=back

 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::NameNode::setup({
       namenode_role => "primary",
    });
 };

=item format_hdfs

This task will format the NameNode. Use it carefully!

=item start

This task will start the Hadoop NameNode service and ensure that the service start at boot.

=item stop

This task will stop the Hadoop NameNode service.

=item restart

This task will restart the Hadoop NameNode service.

=back

=cut
