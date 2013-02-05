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
# TASK: setup
#
task "pseudo_cluster", sub {

   my $param = shift;

   # install package
   update_package_db;
   install package => &get_package($param);

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
