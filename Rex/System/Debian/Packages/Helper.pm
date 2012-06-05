#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: 
# LICENSE: Apache License 2.0
# 
# Helper Task to install or remove packages listed in a file
# created with dpkg --get-selections.

# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::System::Debian::Packages::Helper;
   
use strict;
use warnings;

use Rex -base;

task sync_selections => sub {
   my $param = shift;

   my $file = $param->{file};

   open(my $fh, "<", $file) or die($!);
   while(my $line = <$fh>) {
      chomp $line;
      my ($pkg, $action) = split(/\s+/, $line);
      if($action eq "install") {
         install package => $pkg;
      }
      else {
         remove $pkg;
      }
   }
   close($fh);
};

1;

=pod

=head2 Helper Functions for Debian Package Management

=head2 USAGE

Put it in your I<Rexfile>

 include qw/Rex::System::Debian::Packages::Helper/;
   
 task prepare => sub {
    Rex::System::Debian::Packages::Helper::sync_selections({
      file => "pkg-export.list",
    });
 };

=cut


