#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Ext::DevDir;

use Rex -base;
use Rex::Logger;
use Devel::StackTrace;
use Data::Dumper;
require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(files templates);

sub files {
   my ($file) = @_;
   return _calc_path("files", $file, caller);
}

sub templates {
   my $file = shift;
   my @vars = @_;

   if(ref $_[0] eq "HASH") {
      @vars = %{ $_[0] };
   }

   if(scalar @vars == 1 && ! defined $vars[0]) {
      @vars = ();
   }

   return template(_calc_path("templates", $file, caller), @vars);
}

sub _calc_path {
   my ($prefix, $file, @caller) = @_;

   my $env_file = "$prefix/" . environment . "/$file";
   $env_file = Rex::Helper::Path::get_file_path($env_file, @caller);

   Rex::Logger::debug("Trying to find environment file: $env_file");

   if(! -f $env_file) {
      $env_file = "$prefix/$file";
      $env_file = Rex::Helper::Path::get_file_path($env_file, @caller);
      Rex::Logger::debug("Environment file not found using: $env_file");
   }

   return $env_file;
}

=pod

=head1 NAME

Rex::Ext::DevDir - Put environment files in a seperate directory.

With this extension it is possible to seperate environment-files with the help of directories.


=head1 SYNOPSIS

Assume you have a filestructure like this:

 + files   # (or templates)
 |
 +--+ live
    +--+ apache.conf
    |  + my.cnf
    + test
    +--+ apache.conf
    |  + my.cnf
    + apache.conf
    + my.cnf


 use Rex::Ext::DevDir;
   
 task "prepare", sub {
    file "/etc/apache2/apache2.conf",
       source => files("apache.conf");
    
    file "/etc/apache2/apache2.conf",
       content => templates("apache.conf");
 };


If you execute your Rexfile with the environment I<live> it will use the files from I<files/live> (or I<templates/live>). If the file is not found in the environment directory it will fallback to the base directory.

=cut

1;
