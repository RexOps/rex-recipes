#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: 
# LICENSE: Apache License 2.0
# 
# Simple Module to install Cpanm on your Server.
#
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Lang::Perl::Cpanm;
   
use strict;
use warnings;

use Rex -feature => ['exec_autodie'];
use Rex::Logger;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
    
@EXPORT = qw(cpanm);

sub cpanm {
   my ($action, @values) = @_;

   if($action eq "-install") {
      $action = "install";
   }

   if($action eq "install") {
      if(@values) {
         _install(@values);
      }
      else {
         run "curl -L http://cpanmin.us | perl - --self-upgrade";
         if($? != 0) {
            die("Installing cpanminus failed. Is curl installed?");
         }
         Rex::Logger::info("cpanminus installed.");
      }
   }

   if($action eq "-installdeps") {
      _install_deps(@values);
   }
}

sub _install {
   my ($modules, %option);

   if(ref($_[0]) eq "ARRAY") {
      ($modules, %option) = @_;
   }
   else {
      $modules = [ @_ ];
   }

   my $cpanm_exec = Rex::Config->get("cpanm") || "cpanm";

   for my $mod (@{ $modules }) {
      Rex::Logger::info("Installing $mod");
      if(exists $option{to}) {
         run "$cpanm_exec -L " . $option{to} . " $mod";
      }
      else {
         run "$cpanm_exec $mod";
      }
   }
}

sub _install_deps {
   my ($path) = @_;

   $path ||= ".";

   my $cpanm_exec = Rex::Config->get("cpanm") || "cpanm";

   Rex::Logger::info("Running installdeps for $path");
   run "$cpanm_exec --installdeps $path";
}

1;

=pod

=head1 NAME

Rex::Lang::Perl::Cpanm - Module to install and use Cpanm.

=head1 USAGE

Put it in your I<Rexfile>

 use Rex::Lang::Perl::Cpanm;
   
 set cpanm => "/opt/local/bin/cpanm";   # if you have installed cpanm in no default path
   
 task "prepare", sub {
    cpanm -install;   # install cpanminus
    cpanm -install => [ 'Test::More', 'Foo::Bar' ];
    cpanm -install => [ 'Test::More', 'Foo::Bar' ],
               to => "libs";
                  
    cpanm -installdeps => ".";
 };

=back

=cut

