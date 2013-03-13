#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com> 
# REQUIRES: Rex::Lang::Java
#           Rex::Framework::Cloudera::Hadoop
#           Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3 
# DESC:     Configure a Hadoop Cluster (Pseudo and Real)
#

package Rex::Framework::Cloudera::Hadoop::Configure;

use strict;
use warnings;

use Rex -base;

# define os-distribution specific package names
my %package_name_pseudo_cluster_cdh3 = (
   Debian => "hadoop-0.20-conf-pseudo",
   Ubuntu => "hadoop-0.20-conf-pseudo",
);

my %package_name_pseudo_cluster_mrv1_cdh4 = (
   Debian => "hadoop-0.20-conf-pseudo",
   Ubuntu => "hadoop-0.20-conf-pseudo",
);

my %package_name_pseudo_cluster_mrv2_cdh4 = (
   Debian => "hadoop-conf-pseudo",
   Ubuntu => "hadoop-conf-pseudo",
);

#
# REX-TASK: pseudo_cluster
#
task "pseudo_cluster", sub {

   my $param = shift;

   # install package
   update_package_db;
   install package => &get_package($param);

};

#
# REX-TASK: real_cluster
#
task "real_cluster", sub {
  
  my $param = shift;
  
  # some needed extra modules
  use Cwd qw(getcwd);
  use Date::Format;
  use Rex::Commands::Rsync;
  
  # set uniq timestamp for config folder through Rexfile.lock
  my %uniq_timestamp = stat(getcwd . "/Rexfile.lock");
  my $conf_folder_timestamp = time2str("%Y-%m-%d-%H%M%S", $uniq_timestamp{"mtime"});
  
  # determine the hadoop config files
  my $conf_folder;
  
  # check given config folder if it exists (relativ or absolut)
  # otherwise check the standard rex files folder relativ to Rexfile
  if(defined($param->{"hadoop_conf_folder"})) {
     if(is_dir(getcwd . $param->{"hadoop_conf_folder"})) {
        my $conf_folder = getcwd . $param->{"hadoop_conf_folder"};
     }
     elsif(is_dir($param->{"hadoop_conf_folder"})) {
        my $conf_folder = $param->{"hadoop_conf_folder"};
     }
     else {
        die("Your given Hadoop-Config-Folder to synchronize with the Cluster does not exists.");
     }
  }
  else {
     if(is_dir(getcwd . "/files/etc/hadoop")) {
        my $conf_folder = getcwd . "/files/etc/hadoop";
     }
     else {
        die("Please specify your Hadoop-Config-Folder to synchronize with the Cluster.");
     }
  }
  
  # sudo/rsync error preventing - because if this module running
  # through sudo (like rex -s) then rsync will not correctly
  # sync the config folder (e.g. set attributes)
  chmod(777, "/etc/hadoop");
  
  # create the uniq config folder for the new hadoop config and
  # do the same sudo/rsync error preventing
  mkdir("/etc/hadoop/conf.$conf_folder_timestamp");
  chmod(777, "/etc/hadoop/conf.$conf_folder_timestamp");
  
  # sync the configuration to the new hadoop config folder
  sync "$conf_folder/", "/etc/hadoop/conf.$conf_folder_timestamp/", {
     parameters => "--archive --omit-dir-times --no-o --no-g --no-p",
  };
  
  # redo the sudo/rsync error preventing
  chmod(755, "/etc/hadoop");
  chmod(755, "/etc/hadoop/conf.$conf_folder_timestamp");
  chown("root", "/etc/hadoop/conf.$conf_folder_timestamp", recursive => 1);
  chgrp("root", "/etc/hadoop/conf.$conf_folder_timestamp", recursive => 1);
  
  # finaly advertise the new config folder to alternatives and
  # activate the new configuration for hadoop
  run "update-alternatives --install /etc/hadoop/conf hadoop-conf /etc/hadoop/conf.$conf_folder_timestamp 50";
  run "update-alternatives --set hadoop-conf /etc/hadoop/conf.$conf_folder_timestamp"; 

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
         %package_name = %package_name_pseudo_cluster_cdh3;
      }
      elsif($cdh_version eq "cdh4") {
         %package_name = %package_name_pseudo_cluster_mrv1_cdh4;
      }
   }
   elsif($param->{"mr_version"} eq "mrv2") {
      if($cdh_version eq "cdh3") {
         die("MapReduce Version 2 is not supported by CDH3.");
      }
      elsif($cdh_version eq "cdh4") {
         %package_name = %package_name_pseudo_cluster_mrv2_cdh4;
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

1;

=pod

=head1 NAME

Rex::Framework::Cloudera::Hadoop::Configure - Configure a Hadoop Cluster (Pseudo and Real)

=head1 DESCRIPTION

This Rex-Module configures a Hadoop Cluster (Pseudo and Real).

=head1 USAGE

Put it in your I<Rexfile>

 require Rex::Framework::Cloudera::Hadoop::Configure;

 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::Configure::pseudo_cluster({
       mr_version => "mrv1",
    });
 };

And call it:

 rex -H $host yourtask

=head1 TASKS

=over 4

=item pseudo_cluster

This task will configure a Hadoop Pseudo-Cluster.

=over 4

=item mr_version

Define the MapReduce Version of the Hadoop-Pseudo-Cluster. Valid parameters
are "mrv1" (MapReduce Version 1) or "mrv2" (MapReduce Version 2).

=back

 task yourtask => sub {
    Rex::Framework::Cloudera::Hadoop::Configure::pseudo_cluster({
       mr_version => "mrv1",
    });
 };

=back

=cut
