#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Commands::Concat;

use Carp;
use Rex -base;
use Rex::Commands::MD5;
require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(concat_fragment concat);

sub concat {
  my ( $file, %param ) = @_;

  $param{ensure} ||= "present";

  if($param{ensure} eq "absent") {
    file $file, ensure => "absent";
    return;
  }

  my $tmp_dir        = Rex::Config->get_tmp_dir;
  my $tmp_concat_dir = $file;
  $tmp_concat_dir =~ s/[^a-zA-Z0-9]/_/g;
  $tmp_concat_dir = "$tmp_dir/$tmp_concat_dir";

  my ( $old_md5, %old_stat );
  eval {
    $old_md5  = md5($file);
    %old_stat = stat($file);
  };

  run "cat $tmp_concat_dir/* >$tmp_concat_dir.tmp";
  my $tmp_md5 = md5("$tmp_concat_dir.tmp");

  my $changed = 0;
  if ( $old_md5 && $old_md5 eq $tmp_md5 ) {

    # nothing to do
    $changed = 0;
  }
  else {
    mv "$tmp_concat_dir.tmp", $file;
    $changed = 1;
  }

  chmod $param{mode}, $file if ( exists $param{mode} );
  chown $param{owner}, $file if ( exists $param{owner} );
  chgrp $param{group}, $file if ( exists $param{group} );

  my %new_stat = stat($file);

  $changed = 1 if ( %old_stat && $old_stat{mode} ne $new_stat{mode} );
  $changed = 1 if ( %old_stat && $old_stat{uid} ne $new_stat{uid} );
  $changed = 1 if ( %old_stat && $old_stat{gid} ne $new_stat{gid} );

  if ($changed) {
    if ( exists $param{on_change} && ref $param{on_change} eq "CODE" ) {
      $param{on_change}->( $file, %param );
    }
  }

  rmdir $tmp_concat_dir;
}

sub concat_fragment {
  my ( $res_name, %param ) = @_;

  my $tmp_dir        = Rex::Config->get_tmp_dir;
  my $tmp_concat_dir = $param{target};
  $tmp_concat_dir =~ s/[^a-zA-Z0-9]/_/g;
  $tmp_concat_dir = "$tmp_dir/$tmp_concat_dir";

  my $fragment_name = $res_name;
  $fragment_name =~ s/[^a-zA-Z0-9]/_/g;

  if ( !is_dir($tmp_concat_dir) ) {
    mkdir $tmp_concat_dir;
  }

  file "$tmp_concat_dir/$param{order}_$fragment_name",
    content => $param{content};
}

=pod

=head1 NAME

Rex::Commands::Concat - A small helper to ease the management of large configuration files.

=head1 DESCRIPTION

With this module you can manage the creation of large configuration files that doesn't support conf.d folders.

You can write as many concat_fragments as you need. And at the end of your code you can create the configuration file with the concat() call.


=head1 USAGE

Put it in your I<Rexfile>

 use Rex::Commands::Concat;

 task prepare => sub {
   concat_fragment "config-header",
     target  => "/the/file.conf",
     content => "# managed by Rex",
     order   => "01";
 };

 task setup => sub {
   concat_fragment "first-entry",
     target  => "/the/file.conf",
     content => "the content",
     order   => "20";

   # create the file
   concat "/the/file.conf",
     owner => "root",
     group => "root",
     mode  => 600,
     on_change => sub { say "something changed."; };
 };

=cut

1;
