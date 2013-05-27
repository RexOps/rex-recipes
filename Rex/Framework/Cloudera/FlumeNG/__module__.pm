#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com> 
# REQUIRES: Rex::Lang::Java
#           Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3 
# DESC:     Creates and Configure a FlumeNG-Server
#  

package Rex::Framework::Cloudera::FlumeNG;

use strict;
use warnings;

use Rex -base;

# define os-distribution specific package names
my %package_name_without_agent_daemon = (
   Debian => "flume-ng",
   Ubuntu => "flume-ng",
);

my %package_name_with_agent_daemon = (
   Debian => ["flume-ng", "flume-ng-agent"],
   Ubuntu => ["flume-ng", "flume-ng-agent"],
);

# define os-distribution specific service names
my %service_name = (
   Debian => "flume-ng-agent",
   Ubuntu => "flume-ng-agent",
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
# REX-TASK: config
#
task "config", sub {
  
  my $param = shift;
  
  # some needed extra modules
  use Cwd qw(getcwd);
  use Date::Format;
  use Rex::Commands::Rsync;
  
  # determine config folder and timestamp from local machine  
  LOCAL {
      # set uniq timestamp for config folder through Rexfile.lock
      my %uniq_timestamp = stat(getcwd . "/Rexfile.lock");
      our $conf_folder_timestamp = time2str("%Y-%m-%d-%H%M%S", $uniq_timestamp{"mtime"});
      
      # set flume config folder
      our $conf_folder;
      
      # check given config folder if it exists (relativ or absolut)
      # otherwise check the standard rex files folder relativ to Rexfile
      if(defined($param->{"flumeng_conf_folder"})) {
         if(is_dir(getcwd . "/" . $param->{"flumeng_conf_folder"})) {
            $conf_folder = getcwd . "/" . $param->{"flumeng_conf_folder"};
         }
         elsif(is_dir($param->{"flumeng_conf_folder"})) {
            $conf_folder = $param->{"flumeng_conf_folder"};
         }
         else {
            die("Your given FlumeNG-Config-Folder to synchronize with the Server does not exists.");
         }
      }
      else {
         if(is_dir(getcwd . "/files/etc/flume-ng/conf")) {
            $conf_folder = getcwd . "/files/etc/flume-ng/conf";
         }
         else {
            die("Please specify your FlumeNG-Config-Folder to synchronize with the Cluster.");
         }
      }
  };
  
  # set config folder and timestamp in current scope
  my $conf_folder = $Rex::Framework::Cloudera::FlumeNG::conf_folder;
  my $conf_folder_timestamp = $Rex::Framework::Cloudera::FlumeNG::conf_folder_timestamp;
  
  # sudo/rsync error preventing - because if this module running
  # through sudo (like rex -s) then rsync will not correctly
  # sync the config folder (e.g. set attributes)
  chmod(777, "/etc/flume-ng");
  
  # create the uniq config folder for the new flume config and
  # do the same sudo/rsync error preventing
  mkdir("/etc/flume-ng/conf.$conf_folder_timestamp");
  chmod(777, "/etc/flume-ng/conf.$conf_folder_timestamp");
  
  # sync the configuration to the new flume config folder
  sync "$conf_folder/", "/etc/flume-ng/conf.$conf_folder_timestamp/", {
     parameters => "--archive --omit-dir-times --no-o --no-g --no-p",
  };
  
  # redo the sudo/rsync error preventing
  chmod(755, "/etc/flume-ng");
  chmod(755, "/etc/flume-ng/conf.$conf_folder_timestamp");
  chown("root", "/etc/flume-ng/conf.$conf_folder_timestamp", recursive => 1);
  chgrp("root", "/etc/flume-ng/conf.$conf_folder_timestamp", recursive => 1);
  
  # finaly advertise the new config folder to alternatives and
  # activate the new configuration for hadoop
  run "update-alternatives --install /etc/flume-ng/conf flume-ng-conf /etc/flume-ng/conf.$conf_folder_timestamp 50";
  run "update-alternatives --set flume-ng-conf /etc/flume-ng/conf.$conf_folder_timestamp"; 

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

   # determine package name addicted with or without flume agent
   my %package_name;

   if($param->{"with_agent_daemon"} == 0) {
      %package_name = %package_name_without_agent_daemon;
   }
   elsif($param->{"with_agent_daemon"} == 1) {
      %package_name = %package_name_with_agent_daemon;
   }
   else {
      die("Valid parameter is 0 (without FlumeNG-Agent Daemon) or 1 (with FlumeNG-Agent Daemon).");
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

   # defining service based on os-distribution and return it
   my $service = $service_name{get_operating_system()};

   die("Your Linux-Distribution is not supported by this Rex-Module.") unless $service;

   return $service;

};

1;

=pod

=head1 NAME

Rex::Framework::Cloudera::FlumeNG - Creates and Configure a FlumeNG-Server

=head1 DESCRIPTION

Flume is a distributed, reliable, and available service for efficiently collecting,
aggregating, and moving large amounts of log data. Its main goal is to deliver data
from applications to Hadoop’s HDFS.

This Rex-Module creates and configure a FlumeNG-Server.

=head1 USAGE

Put it in your I<Rexfile>

 require Rex::Framework::Cloudera::FlumeNG;
  
 task yourtask => sub {
    Rex::Framework::Cloudera::FlumeNG::setup({
       with_agent_daemon => 1,
    });
 };

And call it:

 rex -H $host yourtask

=head1 TASKS

=over 4

=item setup

This task will install the FlumeNG-

=over 4

=item with_agent

Define if FlumeNG should installed with the FlumeNG-Agent Daemon.

=back

 task yourtask => sub {
    Rex::Framework::Cloudera::FlumeNG::setup({
       with_agent_daemon => 1,
    });
 };

=back

=item config

This task will configure FlumeNG Server.

=over 4

=item flumeng_conf_folder

Define the folder where your local FlumeNG-Configuration placed. This folder will
synced to your FlumeNG-Server. If you don't specify an folder where your FlumeNG-
Configuration is stored Rex will choose the default files-folder. Then you have
to place your configuration relativ to your Rexfile under files/etc/flume-ng/conf.  

=back

task yourtask => sub {
   Rex::Framework::Cloudera::Hadoop::FlumeNG::config({
      flumeng_conf_folder => "/foo/bar"
   });
};

=item start

This task will start the FlumeNG-Agent Daemon and ensure that the service start at boot.

=item stop

This task will stop the FlumeNG-Agent Daemon.

=item restart

This task will restart the FlumeNG-Agent Daemon.

=back

=cut
