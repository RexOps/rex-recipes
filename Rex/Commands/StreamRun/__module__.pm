#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::Commands::StreamRun;

use strict;
use warnings;

use Rex -base;
use Data::Dumper;
use Carp;
use IPC::Open3::Simple;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
    
@EXPORT = qw(stream_run);

Rex::Config->set(connection => 'OpenSSH');

sub stream_run {
  my $cmd = shift;
  my $cb  = shift;

  confess "No command given." unless $cmd;
  confess "No callback given." unless $cb;

  my $ssh = Rex::is_ssh;

  if(! $ssh) {
    # local run
    my $ipc = IPC::Open3::Simple->new(out => sub {
      $cb->($_[0]);
    }, err => sub {
      $cb->($_[0]);
    });
    $ipc->run($cmd);
  }

  elsif(ref $ssh eq "Net::OpenSSH") {
    my ($pty, $pid) = $ssh->open2pty($cmd);
    while(my $line = <$pty>) {
      $line =~ s/([\r\n])$//g;
      $cb->($line);
    }
  }
  else {
    confess "Only works with OpenSSH connection mode.";
  }

}


1;


=pod

=head1 NAME

Rex::Commands::StreamRun - Run a command and capture the output line by line

If you need to capture the output from a command line by line, this module is for you. This module only works with I<OpenSSH> connection mode, which is default since 1.0.

=head1 SYNOPSIS

 use Rex::Commands::StreamRun;
  
 group servers => "frontend-[01..05]";
    
 task "do_something", sub {
   stream_run "ls -l", sub {
     my ($line) = @_;
     print connection->server . ": [$line]\n";
   };
 };


