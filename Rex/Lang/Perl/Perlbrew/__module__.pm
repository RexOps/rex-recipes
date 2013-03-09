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
 
package Rex::Lang::Perl::Perlbrew;
   
use strict;
use warnings;

use Rex -base;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

use Rex::Config;
    
@EXPORT = qw(perlbrew);

use vars qw($perlbrew_root);

$perlbrew_root = "/opt/perlbrew";

Rex::Config->register_set_handler("perlbrew" => sub {
   my ($key, $value) = @_;
   if($key eq "root" || $key eq "-root") {
      $perlbrew_root = $value;
   }
});

sub perlbrew {
   my ($action, @values) = @_;

   if($action =~ m/^\-/) {
      $action = substr($action, 1);
   }

   if($action eq "init") {
      _init();
   }

   if($action eq "use") {
      _use(@values);
   }

   if($action eq "install") {
      if(@values) {
         _install(@values);
      }
      else {
         _install("perlbrew");
      }
   }

   if($action eq "root") {
      $perlbrew_root = $values[0];
   }

}

sub _set_path {
   my ($version) = @_;

   my @new_path = ();

   if(defined $version) {
      push(@new_path, $perlbrew_root . "/perls/$version/bin");
   }
   push(@new_path, $perlbrew_root . "/bin");
   push(@new_path, Rex::Config->get_path);

   Rex::Config->set_path(\@new_path);
}
sub _init {
   _set_path();
   Rex::Logger::info("Initializing Perlbrew to $perlbrew_root");
   run "PERLBREW_ROOT=$perlbrew_root perlbrew init";
}

sub _use {
   Rex::Logger::info("Switching to perl $_[0]");
   _set_path(@_);
}

sub _install {
   my (@things) = @_;

   _set_path();

   if(! can_run("perlbrew") && $things[0] ne "perlbrew") {
      Rex::Logger::info("Need to install perlbrew first.");
      unshift(@things, "perlbrew");
   }

   for my $version (@things) {
      if($version eq "perlbrew") {
         Rex::Logger::info("Downloading and installing Perlbrew...");
         run "curl -kL http://install.perlbrew.pl | PERLBREW_ROOT=$perlbrew_root sh";
         if($? != 0) {
            Rex::Logger::info("You need curl to install Perlbrew.", "warn");
            die "You need curl to install Perlbrew.";
         }
      }
      elsif($version eq "cpanm") {
         Rex::Logger::info("Instaling cpanm...");
         run "PERLBREW_ROOT=$perlbrew_root perlbrew install-cpanm";
         if($? != 0) {
            Rex::Logger::info("Error installing cpanm", "warn");
            die("Error installing cpanm");
         }
      }
      else {
         Rex::Logger::info("Installing perl $version...");
         run "PERLBREW_ROOT=$perlbrew_root perlbrew install $version";
         if($? != 0) {
            Rex::Logger::info("Error installing perlbrew version $version", "warn");
            die("Error installing perlbrew version $version");
         }
      }
   }
}


1;

=pod

=head1 NAME

Rex::Lang::Perl::Perlbrew - Module to install and use Perlbrew.

=head1 USAGE

Put it in your I<Rexfile>

 use Rex::Lang::Perl::Perlbrew;
   
 # set the perlbrew root
 # defaults to: /opt/perlbrew
 set perlbrew => root => "/opt/myperl";
    
 task "prepare", sub {

    perlbrew -install;
      
    perlbrew -install => qw/ 
                        perl-5.16.0
                        cpanm
                        /;
                          
    perlbrew -use => "perl-5.16.0";
       
    run "perl -v";
 };

=back

=cut

