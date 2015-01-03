#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::Commands::DockerBuild::DockerImage;

use strict;
use warnings;

require Rex::Commands::Run;
use Carp;
use Rex::Commands::DockerBuild::DockerImage::Tag;

sub new {
  my $that = shift;
  my $proto = ref($that) || $that;
  my $self = { @_ };

  bless($self, $proto);

  $self->{__docker_file__} = [];

  return $self;
}

sub name {
  my ($self, $name) = @_;
  $self->{name} = $name if $name;
  return $self->{name};
}

sub id {
  my ($self, $id) = @_;
  $self->{id} = $id if $id;
  return $self->{id};
}

for my $func (qw/from maintainer run cmd expose env add copy entrypoint user workdir/) {
  no strict;
  *{__PACKAGE__ . "::$func"} = sub {
    my ($self, @p) = @_;
    push @{$self->{__docker_file__}}, uc($func) . " " . join(" ", @p);
  };
  use strict;
}

sub volume {
  my ($self, $vol) = @_;
    push @{$self->{__docker_file__}}, "VOLUME [\"$vol\"]";
}

sub tag {
  my ($self, $tag) = @_;
  my $tag_o = Rex::Commands::DockerBuild::DockerImage::Tag->new(image => $self, tag => $tag);
  $tag_o->tag();

  return $tag_o;
}

sub to_string {
  my ($self) = @_;
  return join("\n", @{ $self->{__docker_file__} });
}

1;
