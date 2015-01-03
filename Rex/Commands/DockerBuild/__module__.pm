#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Commands::DockerBuild;

use strict;
use warnings;
use Rex::Commands::DockerBuild::DockerImage;
use File::Spec;
use Rex::Helper::Path;
require Rex::Commands::Fs;
require Rex::Commands::File;
require Rex::Commands::Run;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
    
@EXPORT = qw(docker_build);

sub docker_build(&) {
  my $code = shift;
  my $image = Rex::Commands::DockerBuild::DockerImage->new;
  $code->($image);

  my $tmp_dir = get_tmp_file;

  Rex::Commands::Fs::mkdir("$tmp_dir/" . $image->name);
  Rex::Commands::File::file("$tmp_dir/" . $image->name . "/Dockerfile", content => $image->to_string);

  my @output = Rex::Commands::Run::run("docker build  -t '" . $image->name . "' . ", cwd => "$tmp_dir/" . $image->name);
  my ($image_line) = grep { m/Successfully built/i } @output;
  my ($image_id)   = ( $image_line =~ m/([a-f0-9]+)/i );

  $image->id($image_id);

  Rex::Commands::Fs::rmdir($tmp_dir);
  
  return $image;
}

=pod

=head1 NAME

Rex::Commands::DockerBuild - A small helper module to build docker images.

=head1 DESCRIPTION

This module is a small helper to build docker containers from within your Rexfile. This module will create a Dockerfile and run docker build to create the container. Later you can also tag and publish your container.

=head1 USAGE

Put it in your I<Rexfile>

 use Rex::Commands::DockerBuild;
     
 task dockerize => sub {
   my $docker_image = docker_build {
     my $docker = shift;
     $docker->name("myapp");
     $docker->from("dockerfile/java");
     $docker->cmd("mkdir /app");
     $docker->copy("releases/myapp.jar", "/app/myapp.jar");
   };

   $docker_image->tag("myhub:3000/myapp")->push;
 };

=cut

1;
