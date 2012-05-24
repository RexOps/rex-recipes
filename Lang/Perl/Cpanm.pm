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
   
package Lang::Perl::Cpanm;
   
use strict;
use warnings;

use Rex -base;
use Rex::Logger;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
    
@EXPORT = qw(cpanm);

sub cpanm {
   my ($action, @values) = @_;

   if($action eq "install") {
      _install(@values);
   }

   if($action eq "-installdeps") {
      _install_deps(@values);
   }
}

sub _install {
   my ($modules, %option) = @_;

   for my $mod (@{ $modules }) {
      Rex::Logger::info("Installing $mod");
      if(exists $option{to}) {
         run "cpanm -L " . $option{to} . " $mod";
      }
      else {
         run "cpanm $mod";
      }
   }
}

sub _install_deps {
   my ($path) = @_;

   $path ||= ".";

   Rex::Logger::info("Running installdeps for $path");
   run "cpanm --installdeps $path";
}

1;

=pod

=head2 Module to install and use Cpanm.

This module installs Cpanm.

=head2 USAGE

Put it in your I<Rexfile>

 use Lang::Perl::Cpanm;
   
 task "prepare", sub {
    cpanm install => [ 'Test::More', 'Foo::Bar' ];
    cpanm install => [ 'Test::More', 'Foo::Bar' ],
               to => "libs";
                  
    cpanm -installdeps => ".";
 };

=back

=cut

