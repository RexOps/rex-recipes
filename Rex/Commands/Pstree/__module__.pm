#
# (c) fanyeren
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Commands::Pstree;


use strict;
use warnings;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(pstree);

=item pstree

Will return all fields of a I<pstree <param>>.

 task "pstree", "server01", sub {
    for my $process (pstree("<param>")) {
      say $process;
    }
 };

=cut

sub pstree {
   my $param = shift;
   my @list;

   use Rex::Commands::User;

   unless (!get_user($param) || ($param =~ m/^\d+$/xms && run("kill -0 " . $param. " && echo \$?") eq "0")) {
      Rex::Logger::info("$param not exists or not permitted.", "warn");
      return @list;
   }


   if(operating_system_is("SunOS") && operating_system_version() <= 510) {
      @list = run("/usr/ucb/pstree $param");
   }
   else {
      @list = run("pstree $param");
   }

   if($? != 0) {
      die("Error running pstree");
   }

   return @list;
}



1;

=pod

=head1 NAME

Rex::Commands::Pstree - Module to run pstree

=head1 USAGE

Put it in your I<Rexfile>

 use Rex::Commands::Pstree;
     
 task prepare => sub {
    my @return = pstree("<param>");
 };

