#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::FS::Watch;

use strict;
use warnings;

use Rex -base;
use English;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(watch);

$SIG{INT} = sub {
  unlink "Rexfile.lock";
};

sub watch {
  my $param = shift;
  my ($fs);

  if($OSNAME eq "darwin") {
    eval "use Rex::FS::Watch::OS::Mac";
    if($EVAL_ERROR) {
      die("Error loading Watch Class for Mac ($EVAL_ERROR).");
    }

    $fs = Rex::FS::Watch::OS::Mac->new(%{$param}, cb => sub {
      _call_task(@_);
    });
  }

  $fs->watch;
}

sub _call_task {
  my ($task, @paths) = @_;
  if(Rex::TaskList->create()->is_task($task)) {
    Rex::Logger::debug("Running task: $task");
    Rex::TaskList->create()->run($task, params => {changed => \@paths});
  }
  else {
    die("Task $task not found.");
  }
}

1;

=pod

=head1 NAME

Rex::FS::Watch - A module to watch filesystem changes

With this module you can watch filesystem changes and execute a task when they
occurs.

This is nice during development, so you can upload local files to a remote
system if you save it.

This module currently only works on MacOS!

=head1 USAGE

  use Rex::FS::Watch;

  group dev => '172.16.120.143';

  user "root";
  password "box";

  task "watch", sub {
    watch { directory => '.', task => 'upload' };
  };

  task "upload", group => "dev", sub {
    my $param = shift;
    my $project_dir = "/remote/directory";

    for my $event (@{ $param->{changed} }) {
      if($event->{event} eq 'deleted') {
        rm "$project_dir/$event->{relative_path}"    if($event->{type} eq 'file');
        rmdir "$project_dir/$event->{relative_path}" if($event->{type} eq 'dir');
      }
      else {
        file "$project_dir/$event->{relative_path}",
          source =>  $event->{path}                  if($event->{type} eq "file");

        mkdir "$project_dir/$event->{relative_path}" if($event->{type} eq "dir");
      }
    }
  };

=head1 EXPORTED FUNCTIONS

=over 4

=item watch

The I<watch> function monitors a directory for changes.

Possible options are:

=over 8

=item directory (required)

=item task (required)

=item latency, in seconds. default 10

=item skip, ArrayRef[RegExp], default [qr{^\.git/}, qr{.sw.$}]

=back

=back

=cut
