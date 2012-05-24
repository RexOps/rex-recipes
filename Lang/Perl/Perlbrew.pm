#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: 
# LICENSE: Apache License 2.0
# 
# Simple Module to install Perlbrew on your Server.
#
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
 
package Lang::Perl::Perlbrew;
   
use strict;
use warnings;

use Rex -base;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

use Rex::Config;
    
@EXPORT = qw(perlbrew);

use vars qw($perlbrew_root);

Rex::Config->register_set_handler("perlbrew" => sub {
   my ($key, $value) = @_;
   if($key eq "root" || $key eq "-root") {
      $perlbrew_root = $value;
   }
});

sub perlbrew {
   my ($action, @values) = @_;

   if($action eq "init" || $action eq "-init") {
      _init();
   }

   if($action eq "use" || $action eq "-use") {
      _use(@values);
   }

   if($action eq "install" || $action eq "-install") {
      _install(@values);
   }

   if($action eq "root" || $action eq "-root") {
      $perlbrew_root = $values[0];
   }

}

sub _init {
   run "PERLBREW_ROOT=$perlbrew_root perlbrew init";
}

sub _use {
   my ($version) = @_;
   
   my @new_path = ();
   push(@new_path, $perlbrew_root . "/perls/$version/bin");
   push(@new_path, $perlbrew_root . "/bin");
   push(@new_path, Rex::Config->get_path);

   Rex::Config->set_path(\@new_path);

}

sub _install {
   my ($version) = @_;

   if($version eq "perlbrew") {
      run "PERLBREW_ROOT=$perlbrew_root curl -kL http://install.perlbrew.pl | sh perlbrew-install";
   }
   elsif($version eq "cpanm") {
      run "PERLBREW_ROOT=$perlbrew_root perlbrew install-cpanm";
   }
   else {
      run "PERLBREW_ROOT=$perlbrew_root perlbrew install $version";
   }
}


1;

=pod

=head2 Module to install and use Perlbrew.

This module installs Perlbrew.

=head2 USAGE

Put it in your I<Rexfile>

 use Lang::Perl::Perlbrew;
   
 # set the perlbrew root
 # defaults to: /opt/perlbrew
 set perlbrew => root => "/opt/myperl";
    
 task "prepare", sub {
    perlbrew install => "perl-5.16.0";
    perlbrew install => "cpanm";
        
    perlbrew use => "perl-5.16.0";
       
    run "perl -v";
 };

=back

=cut

