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
