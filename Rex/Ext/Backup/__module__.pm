#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   

package Rex::Ext::Backup;

use Rex -base;
use Rex::Hook;
use Data::Dumper;
use File::Basename;

my $no_hook = 0;

sub _backup_file {
   my ($file, @options) = @_;
   _backup($file);
}

sub _backup_upload {
   my ($local, $remote) = @_;
   _backup($remote);
}

sub _backup {
   my ($file) = @_;
   my $server = connection->server;

   return if($no_hook);

   if(is_file($file)) {

      my %stat = stat $file;

      my $loc;
      LOCAL {
         $loc = _get_backup_location($server, $file);
         mkdir dirname($loc);
      };

      download $file, $loc;
      
      LOCAL {
         $no_hook = 1;
         file "$loc.meta", content => Dumper(\%stat);
         $no_hook = 0;
      };

   }
}

sub _get_backup_location {
   my ($server, $file) = @_;

   my $loc = get "backup_location";
   if(! $loc) {
      $loc = "backup/%h/%t";
   }

   my $seconds = time;

   $loc =~ s/%h/$server/g;
   $loc =~ s/%t/$seconds/g;

   $loc =~ s/\/$//;  # remove trailing slash
   $file =~ s/^\///; # remove leading slash

   return $loc . "/$file";
}

register_function_hooks {
   before_change => {
      file   => \&_backup_file,
      upload => \&_backup_upload,
   },
};


1;

=pod

=head1 NAME

Rex::Ext::Backup - A simple backup module

=head1 DESCRIPTION

This module backup remote files that gets overwritten by Rex to a local folder.

=head1 USAGE

To use Rex::Ext::Backup you have to include it and define the backup location. It will also create a I<$file.meta> file where meta information gets stored (for example uid and gid).

 include qw/Rex::Ext::Backup/;
   
 set backup_location => "backup/%h";
    
 task yourtask => sub {
    file "/etc/foo.conf", content => "new content\n";
 };

You can use the following modifiers for your I<backup_location>.

=over 4

=item %h - the hostname

=item %t - the time (epoch seconds)

=back

=cut
