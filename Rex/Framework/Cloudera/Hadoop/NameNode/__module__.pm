#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com>
# REQUIRES: Rex::Lang::Java
#           Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3
# DESC:     Creates a Hadoop NameNode (primary and secondary)
#
# TODO:     - At the moment i don't know if this module is a good place to format and initialize the hdfs?

package Rex::Framework::Cloudera::Hadoop::NameNode;

use strict;
use warnings;

use Rex -base;

# define os-distribution specific package names for cdh3
my %package_name_primary_namenode_cdh3 = (
   Debian => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-namenode",
   Ubuntu => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-namenode",
);

my %package_name_secondary_namenode_cdh3 = (
   Debian => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-secondarynamenode",
   Ubuntu => "hadoop-0.20 hadoop-0.20-native hadoop-0.20-secondarynamenode",
);

# define os-distribution specific package names for cdh4
my %package_name_primary_namenode_cdh4 = (
   Debian => "hadoop-hdfs-namenode",
   Ubuntu => "hadoop-hdfs-namenode",
);

my %package_name_secondary_namenode_cdh4 = (
   Debian => "hadoop-hdfs-secondarynamenode",
   Ubuntu => "hadoop-hdfs-secondarynamenode",
);

# define os-distribution specific service names for cdh3
my %service_name_primary_namenode_cdh3 = (
   Debian => "hadoop-0.20-namenode",
   Ubuntu => "hadoop-0.20-namenode",
);

my %service_name_secondary_namenode_cdh3 = (
   Debian => "hadoop-0.20-secondarynamenode",
   Ubuntu => "hadoop-0.20-secondarynamenode",
);

# define os-distribution specific service names for cdh4
my %service_name_primary_namenode_cdh4 = (
   Debian => "hadoop-hdfs-namenode",
   Ubuntu => "hadoop-hdfs-namenode",
);

my %service_name_secondary_namenode_cdh4 = (
   Debian => "hadoop-hdfs-secondarynamenode",
   Ubuntu => "hadoop-hdfs-secondarynamenode",
);

#
# REX-TASK: setup
#
task "setup", sub {

   my $param = shift;

   # install package
   update_package_db;
   install package => &get_package($param);

};

#
# REX-TASK: format_hdfs
#
task "format_hdfs", sub {

   # format the name-node if is not allready formatted
   if ( is_dir("/var/lib/hadoop-hdfs/cache/hdfs") ) {
      say "The Hadoop Filesystem is already formatted.";
   }
   else {
      run "sudo -u hdfs hdfs namenode -format";
   }

};

#
# REX-TASK: initialize_hdfs
#
task "initialize_hdfs", sub {

   my $param = shift;

   # initialize temp, mapreduce and system directories in the hdfs
   my $temp_dir;
   my $mapred_dir;
   my $system_dir;

   # create the /tmp directory if it not exists
   $temp_dir = run "sudo -u hdfs hadoop fs -test -d /tmp && echo \$?";

   if ( !( $temp_dir =~ /^[+-]?\d+$/ ) ) {
      $temp_dir = 1;
   }

   if ( $temp_dir == 1 ) {
      run "sudo -u hdfs hadoop fs -mkdir /tmp";
      run "sudo -u hdfs hadoop fs -chmod -R 1777 /tmp";
   }
   elsif ( $temp_dir == 0 ) {
      say "Temp-Directory allready created.";
   }

   # create the system directories if they not exists
   # and the mapreduce system directory if not exists
   if ( $param->{"mr_version"} eq "mrv1" ) {
      $mapred_dir = run "sudo -u hdfs hadoop fs -test -d /tmp/mapred/system && echo \$?";
      $system_dir = run "sudo -u hdfs hadoop fs -test -d /var/lib/hadoop-hdfs/cache/mapred/mapred/staging && echo \$?";

      if ( !( $mapred_dir =~ /^[+-]?\d+$/ ) ) {
         $mapred_dir = 1;
      }

      if ( !( $system_dir =~ /^[+-]?\d+$/ ) ) {
         $system_dir = 1;
      }

      if ( $mapred_dir == 1 ) {
         run "sudo -u hdfs hadoop fs -mkdir -p /tmp/mapred/system";
         run "sudo -u hdfs hadoop fs -chown -R mapred:hadoop /tmp/mapred/system";
      }
      elsif ( $mapred_dir == 0 ) {
         say "Mapreduce-Directory allready created.";
      }

      if ( $system_dir == 1 ) {
         run "sudo -u hdfs hadoop fs -mkdir -p /var/lib/hadoop-hdfs/cache/mapred/mapred/staging";
         run "sudo -u hdfs hadoop fs -chmod 1777 /var/lib/hadoop-hdfs/cache/mapred/mapred/staging";
         run "sudo -u hdfs hadoop fs -chown -R mapred /var/lib/hadoop-hdfs/cache/mapred";
      }
      elsif ( $system_dir == 0 ) {
         say "System-Directories allready created.";
      }
   }
   elsif ( $param->{"mr_version"} eq "mrv2" ) {
      $system_dir = run "sudo -u hdfs hadoop fs -test -d /tmp/hadoop-yarn/staging";

      if ( $system_dir == 1 ) {
         run "sudo -u hdfs hadoop fs -mkdir /tmp/hadoop-yarn/staging";
         run "sudo -u hdfs hadoop fs -chmod -R 1777 /tmp/hadoop-yarn/staging";
         run "sudo -u hdfs hadoop fs -mkdir /tmp/hadoop-yarn/staging/history/done_intermediate";
         run "sudo -u hdfs hadoop fs -chmod -R 1777 /tmp/hadoop-yarn/staging/history/done_intermediate";
         run "sudo -u hdfs hadoop fs -chown -R mapred:mapred /tmp/hadoop-yarn/staging";
         run "sudo -u hdfs hadoop fs -mkdir /var/log/hadoop-yarn";
         run "sudo -u hdfs hadoop fs -chown yarn:mapred /var/log/hadoop-yarn";
      }
      elsif ( $system_dir == 0 ) {
         say "System-Directories allready created.";
      }
   }

};

#
# REX-TASK: create_user
#
task "create_user", sub {

   my $param = shift;

   # remove spaces and fit all users in a list
   $param->{"user"} =~ s/\s+//;
   @user = split( /,/, $param->{"user"} );

   # initialize home directories in the hdfs
   my $home_dir;

   # create a home directory for each mapreduce user
   foreach (@user) {
      $home_dir = run "sudo -u hdfs hadoop fs -test -d /user/$_ && echo \$?";

      if ( !( $home_dir =~ /^[+-]?\d+$/ ) ) {
         $home_dir = 1;
      }

      if ( $home_dir == 1 ) {
         run "sudo -u hdfs hadoop fs -mkdir  /user/$_";
         run "sudo -u hdfs hadoop fs -chown $_ /user/$_";
      }
      elsif ( $home_dir == 0 ) {
         say "Home-Directory for user $_ allready created.";
      }
   }

};

#
# REX-TASK: start
#
task "start", sub {

   # ensure that service start at boot and running
   service &get_service => "ensure" => "started";

};

#
# REX-TASK: stop
#
task "stop", sub {

   # stop service
   service &get_service => "stop";

};

#
# REX-TASK: restart
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

   if ( $param->{"namenode_role"} eq "primary" ) {
      if ( $cdh_version eq "cdh3" ) {
         %package_name = %package_name_primary_namenode_cdh3;
      }
      elsif ( $cdh_version eq "cdh4" ) {
         %package_name = %package_name_primary_namenode_cdh4;
      }
   }
   elsif ( $param->{"namenode_role"} eq "secondary" ) {
      if ( $cdh_version eq "cdh3" ) {
         %package_name = %package_name_secondary_namenode_cdh3;
      }
      elsif ( $cdh_version eq "cdh4" ) {
         %package_name = %package_name_secondary_namenode_cdh4;
      }
   }
   else {
      die("Valid parameters are primary (Primary NameNode) or secondary (Secondary NameNode).");
   }

   # defining package based on os-distribution and return it
   my $package = $package_name{ get_operating_system() };

   die("Your Linux-Distribution is not supported by this Rex-Module.")
     unless $package;

   return $package;

}

#
# FUNCTION: get_service
#
sub get_service {

   # determine cloudera-distribution version and set
   # specific package name addicted by name-node role
   my %service_name;
   my $cdh_version = Rex::Framework::Cloudera::PkgRepository::get_cdh_version();

   if ( is_installed( &get_package( { namenode_role => "primary" } ) ) ) {
      if ( $cdh_version eq "cdh3" ) {
         %service_name = %service_name_primary_namenode_cdh3;
      }
      elsif ( $cdh_version eq "cdh4" ) {
         %service_name = %service_name_primary_namenode_cdh4;
      }
   }
   elsif ( is_installed( &get_package( { namenode_role => "secondary" } ) ) ) {
      if ( $cdh_version eq "cdh3" ) {
         %service_name = %service_name_secondary_namenode_cdh3;
      }
      elsif ( $cdh_version eq "cdh4" ) {
         %service_name = %service_name_secondary_namenode_cdh4;
      }
   }
   else {
      die("The Hadoop NameNode is not installed.");
   }

   # defining service based on os-distribution and return it
   my $service = $service_name{ get_operating_system() };

   die("Your Linux-Distribution is not supported by this Rex-Module.")
     unless $service;

   return $service;

}

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

=item format_hdfs

This task will format the NameNode. Use it carefully!

   task yourtask => sub {
      Rex::Framework::Cloudera::Hadoop::NameNode::format_hdfs()
   };

=item initialize_hdfs

This task will initialize the HDFS directory structer.

=over 4

=item mr_version

Define the MapReduce Version of the JobTracker-Service. Valid parameters
are "mrv1" (MapReduce Version 1) or "mrv2" (MapReduce Version 2).

   task yourtask => sub {
      Rex::Framework::Cloudera::Hadoop::NameNode::initialize_hdfs({
         mr_version => "mrv1"
      })
   };

=back

=item create_user

This task creates the home directory for one or more users on the HDFS filesystem.

=over 4

=item user

Define a list of users for which a home directory should be created on the HDFS filesystem.
The users should already exists on the underlying operating system.

   task yourtask => sub {
      Rex::Framework::Cloudera::Hadoop::NameNode::create_user({
         user => "user1, user2, userN"
      });
   };

=back

=item start

This task will start the Hadoop NameNode service and ensure that the service start at boot.

   task yourtask => sub {
      Rex::Framework::Cloudera::Hadoop::NameNode::start()
   };

=item stop

This task will stop the Hadoop NameNode service.

   task yourtask => sub {
      Rex::Framework::Cloudera::Hadoop::NameNode::stop()
   };

=item restart

This task will restart the Hadoop NameNode service.

   task yourtask => sub {
      Rex::Framework::Cloudera::Hadoop::NameNode::restart()
   };

=back

=cut
