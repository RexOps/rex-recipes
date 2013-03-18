#
# AUTHOR:   Daniel Baeurer <daniel.baeurer@gmail.com>
# REQUIRES:
# LICENSE:  GPLv3
# DESC:     Installs Java
#

package Rex::Lang::Java;

use strict;
use warnings;

use Rex -base;

# define os-distribution specific package names
my %package_name = (
   Debian => "%s-%s-%s",
   Ubuntu => "%s-%s-%s",
);

#
# REX-TASK: setup
#
task "setup", sub {

   my $param = shift;

   # check if java provider, version and environment is set
   die("You must specify the Provider of the Java SE to install.") unless $param->{"jse_provider"};
   die("You must specify the Java SE Version to install.") unless $param->{"jse_version"};
   die("You must specify the Java SE Type to install.") unless $param->{"jse_type"};
   
   # defining package based on os-distribution
   my $package = sprintf($package_name{get_operating_system()}, $param->{"jse_provider"}, $param->{"jse_version"}, $param->{"jse_type"});

   die("Your Linux-Distribution is not supported by this Rex-Module.") unless $package;

   # install package
   update_package_db;
   install package => $package;

   # set JAVA_HOME environemnt
   my $java_home = run "readlink -f /usr/bin/javac | sed 's:/bin/javac::'";
   append_if_no_such_line "/etc/environment", "JAVA_HOME=$java_home";
   
};

1;

=pod

=head1 NAME

Rex::Lang::Java - Installs Java

=head1 DESCRIPTION

The Java Plattform Standard Edition - nothing to say more about.

This Rex-Module will install the OpenJDK - a free and open source
implementation of the Java Platform Standard Edition.

=head1 USAGE

Put it in your I<Rexfile>

 require Rex::Lang::Java;

 task yourtask => sub {
    Rex::Lang::Java::setup({
       jse_provider => "openjdk",
       jse_version  => "6",
       jse_type     => "jdk",
    });
 };

And call it:

 rex -H $host yourtask

=head1 TASKS

=over 4

=item setup

This task will install Java.

=over 4

=item jse_provider

Define Provider of the Java Platform Standard Edition. Valid parameters
are "openjdk" (Java SE 6/7), "sun" (Java SE 6) or "oracle" (Java SE 7).

=item jse_version

Define Java Platform Standard Edition Version. Valid parameters are
"6" (Java SE 6) or "7" (Java SE 7).

=item jse_type

Define Java Platform Standard Edition Type. Valid parameters are
"jre" (Java SE Runtime Environment) or "jdk" (Java SE Development Kit).

=back

 task yourtask => sub {
    Rex::Lang::Java::setup({
       jse_provider => "sun",
       jse_version  => "6",
       jse_type     => "jdk",
    });
 };

=back

=cut
