#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::Commands::DockerBuild::DockerImage::Tag;

use strict;
use warnings;

use Carp;
use Rex::Commands::Run;

sub new {
  my $that = shift;
  my $proto = ref($that) || $that;
  my $self = { @_ };

  bless($self, $proto);

  return $self;
}

sub image {
  my ($self) = @_;
  return $self->{image};
}

sub tag {
  my ($self) = @_;

  run "docker tag '" . $self->image->name . "' '$self->{tag}'";
  if($? != 0) {
    confess "Error tagging image.";
  }
}

sub push {
  my ($self) = @_;
  run "docker push '$self->{tag}'";
  if($? != 0) {
    confess "Error pushing image.";
  }
}

1;
