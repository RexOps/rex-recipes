#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Misc::ShellBlock;

use strict;
use warnings;

use Rex::Commands;
use Rex::Commands::Fs;
use Rex::Commands::File;
use Rex::Commands::Run;

require Exporter;

use vars qw(@EXPORT);
@EXPORT = qw(shell_block);
use base qw(Exporter);

sub shell_block {

   my ($shebang, $code) = @_;

   if(! $code) {
      $code = $shebang;
      $shebang = "#!/bin/bash";
   }

   if($shebang !~ m/^#!\//) {
      $shebang = "#!$shebang";
   }

   my @lines = split(/\n/, $code);
   if($lines[0] !~ m/^#!\//) {
      # shebang not there, so add /bin/bash for default
      unshift(@lines, $shebang);
   }

   my $rnd_file = "/tmp/" . get_random(8, 'a' .. 'z') . ".tmp";

   file $rnd_file,
      content => join("\n", @lines),
      mode => 755;

   my $ret = run $rnd_file;

   unlink $rnd_file;

   return $ret;

}

1;

=pod

=head1 NAME

Rex::Misc::ShellBlock - Module to execute a shell block.

=head1 DESCRIPTION

This module exports a function called I<shell_block>. This function will upload your shell script to the remote system and executes it. Returning its output as a string.


=head1 EXPORTED FUNCTIONS

=over 4

=item shell_block($code)

This function will add a default shebang of '#!/bin/bash' to your code if no shebang is found and return its output.

 my $ret = shell_block <<EOF;
 echo "hi"
 EOF


=item shell_block($shebang, $code)

This function will add $shebang to your code and return its output.

 my $ret = shell_block "/bin/sh", <<EOF;
 echo "hi"
 EOF

=back

=head1 USAGE

 use Rex::Misc::ShellBlock;
    
 task "myexec", sub {
    shell_block <<EOF;
 echo "hi"
 EOF
  
 };

