#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com>
# REQUIRES:
# LICENSE:  GPLv3
# DESC:     Adds Package-Repository for Cloudera CDH3 or CDH4
#

package Rex::Framework::Cloudera::PkgRepository;

use strict;
use warnings;

use Rex -base;
 
#
# TASK: setup
#
task "setup", sub {

   my $param = shift;

   # determine os-distribution and os-version
   my $os_distro  = lc(get_operating_system());
   my $os_version = operating_system_version();

   # set distribution-codename and cloudera-distribution 
   # support flag for specific os-distribution
   my $codename;
   my %cdh_supported;

   if($os_distro eq "debian") {
      if($os_version >= 500 && $os_version < 600) {
         $codename      = "lenny";
         %cdh_supported = ( cdh3 => "true", cdh4 => "false");
      }
      if($os_version >= 600 && $os_version < 700) {
         $codename = "squeeze";
         %cdh_supported = ( cdh3 => "true", cdh4 => "true");
      }
      else {
         die("Your Debian-Release is not supported by Cloudera.");
      }
   }
   elsif($os_distro eq "ubuntu") {
      if($os_version >= 1004 && $os_version < 1010) {
         $codename      = "lucid";
         %cdh_supported = ( cdh3 => "true", cdh4 => "true");
      }
      elsif($os_version >= 1010 && $os_version < 1104) {
         $codename = "maverick";
         %cdh_supported = ( cdh3 => "true", cdh4 => "false");
      }
      elsif($os_version >= 1204 && $os_version < 1210) {
         $codename = "precise";
         %cdh_supported = ( cdh3 => "false", cdh4 => "true");
      }
      else {
         die("Your Ubuntu-Release is not supported by Cloudera.");
      }
   }
   else {
      die("Your Linux-Distribution is not supported by Cloudera or by this Rex-Module.");
   }

   # add CDH3 or CDH4 repository
   if($param->{"cdh_version"} == 3 && $cdh_supported{cdh3} eq "true") {
      repository
         add        => "cdh3",
         url        => "http://archive.cloudera.com/debian",
         distro     => $codename . "-cdh3",
         repository => "contrib",
         key_url    => "http://archive.cloudera.com/debian/archive.key",
         source     => 1;
   }
   elsif($param->{"cdh_version"} == 4 && $cdh_supported{cdh4} eq "true") {
      repository
         add        => "cdh4",
         url        => "http://archive.cloudera.com/cdh4/" . $os_distro . "/" . $codename . "/amd64/cdh",
         distro     => $codename . "-cdh4",
         repository => "contrib",
         arch       => "amd64",
         key_url    => "http://archive.cloudera.com/cdh4/" . $os_distro . "/" . $codename . "/amd64/cdh/archive.key",
         source     => 1;
   }
   else {
      die("Your Linux-Distribution is not supported by Cloudera or by this Rex-Module.");
   }

   update_package_db;

};

1;

=pod

=head1 NAME

Rex::Framework::Cloudera::PkgRepository - Adds Package-Repository for Cloudera CDH3 or CDH4

=head1 DESCRIPTION

To install packages from the Cloudera Distribution the corresponding
Cloudera repository must be added to the system.

This Rex-Module will add the Cloudera Repository.

=head1 USAGE

Put it in your I<Rexfile>

 require Rex::Framework::Cloudera::PkgRepository;

 task yourtask => sub {
    Rex::Framework::Cloudera::PkgRepository::setup({
       cdh_version => "4",
    });
 };

And call it:

 rex -H $host yourtask

=head1 TASKS

=over 4

=item setup

This task will add Cloudera Repository.

=over 4

=item cdh_version

Define Cloudera Distribution Version, aka CDH3 or CDH4.

=back

 task yourtask => sub {
    Rex::Framework::Cloudera::PkgRepository::setup({
       cdh_version => "4",
    });
 };

=back

=cut
