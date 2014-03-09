#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::FS::Watch::OS::Mac;

use Moo;
use IO::Select;
use Mac::FSEvents;
use File::Find;
use File::Spec;
use Cwd;
use Data::Dumper;

has directory => (is => 'ro');
has task      => (is => 'ro');
has cb        => (is => 'ro');
has latency   => (is => 'ro', required => 0, default => 10.0);
has skip      => (is => 'ro', required => 0, default => sub { [qr{^\.git/}, qr{.sw.$}] });

sub watch {
  my $self = shift;
  $self->{fs} = Mac::FSEvents->new({
    path    => $self->directory,
    latency => $self->latency,
  });

  $self->{old} = $self->_scan($self->directory);

  my $fh = $self->{fs}->watch;
  my $sel = IO::Select->new($fh);

  while ( $sel->can_read ) {
    my %uniq;
    my @path = grep { !$uniq{$_}++ } map { $_->path } $self->{fs}->read_events;
    my $new_fs = $self->_scan($self->directory);
    my @events;
    $self->_compare($self->{old}, $new_fs, sub {
      push @events, { path => $_[0], event => $_[1], type => $_[2], relative_path => $_[3] };
    });

    my @real_events = grep { ! $self->_to_skip($_->{relative_path}) } grep { $_->{relative_path} !~ m/^(vars\.db|vars\.db\.lock|Rexfile\.lock)$/ } @events;

    next if(@real_events == 0);

    $self->cb->($self->task, @real_events);
    $self->{old} = $new_fs;
  }
}

sub stop {
  my $self = shift;
  $self->{fs}->stop;
}

sub _to_skip {
  my ($self, $path) = @_;
  for my $s (@{ $self->skip }) {
    if($path =~ $s) {
      return 1;
    }
  }

  return 0;
}

sub _compare {
  my($self, $old, $new, $cb) = @_;

  for my $dir (keys %$old) {
    for my $path (keys %{$old->{$dir}}) {
      if (!exists $new->{$dir}{$path}) {
        my $type = 'file';
        if($old->{$dir}{$path}{is_dir}) {
          $type = 'dir';
        }
        $cb->($path, 'deleted', $type, $old->{$dir}{$path}{relative_path}); # deleted
      } elsif (!$new->{$dir}{$path}{is_dir} &&
            ( $old->{$dir}{$path}{mtime} != $new->{$dir}{$path}{mtime} ||
              $old->{$dir}{$path}{size}  != $new->{$dir}{$path}{size})) {
        my $type = 'file';
        if(-d $path) {
          $type = 'dir';
        }
        $cb->($path, 'updated', $type, $old->{$dir}{$path}{relative_path}); # updated
      }
    }
  }

  for my $dir (keys %$new) {
    for my $path (sort grep { !exists $old->{$dir}{$_} } keys %{$new->{$dir}}) {
      my $type = 'file';
      if(-d $path) {
        $type = 'dir';
      }
      $cb->($path, 'new', $type, $new->{$dir}{$path}{relative_path}); # new
    }
  }

}

sub _scan {
  my ($self, $path) = @_;

  my %map;
  File::Find::finddepth({
    wanted => sub {
      my $fullname = $File::Find::fullname || File::Spec->rel2abs($File::Find::name);
      $map{Cwd::realpath($File::Find::dir)}{$fullname} = $self->_stat($fullname);
    },
    follow_fast => 1,
    follow_skip => 2,
    no_chdir    => 1,
  }, $path);

  return \%map;
}

sub _stat {
  my ($self, $path) = @_;
  my @stat = stat $path;
  my $rel_path = $path;
  my $root_dir = File::Spec->rel2abs($self->directory);
  $root_dir    =~ s/\/$//;
  $rel_path =~ s/$root_dir\///;

  return { path => $path, relative_path => $rel_path, mtime => $stat[9], size => $stat[7], is_dir => -d _ };
}

1;
