#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com> 
# REQUIRES: Rex::Lang::Java, Rex::Framework::Cloudera::PkgRepository
# LICENSE:  GPLv3 
# DESC:     Instantiated and configured a MRv2 HistoryServer
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

Rex::Framework::Cloudera::Hadoop::HistoryServer - Instantiated and configured a MRv2 HistoryServer

=head1 DESCRIPTION

The History server keeps records of the different activities being performed
on a Hadoop cluster.

This Rex-Module instantiated and configured a HistoryServer.

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

This task will install the Hadoop HistoryServer-Service.

=back

=cut
