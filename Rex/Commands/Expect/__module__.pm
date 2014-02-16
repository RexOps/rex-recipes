#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Commands::Expect;

use Carp;
use Rex -base;
require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(expect);

my %expect_pkg = (
   ubuntu => 'expect',
   centos => 'expect',
   debian => 'expect',
   redhat => 'expect',
   fedora => 'expect',
   mageia => 'expect',
);



sub expect {
   my ($cmd, %param) = @_;

   my $pkg = $expect_pkg{lc(operating_system)};

   $param{options}->{timeout} ||= 360;

   confess "no expect package found for " . lc(operating_system) . "."
      if(! $pkg);
   confess "no command given." if(! $cmd);
   confess "no answers given." if(! exists $param{answers} || scalar(@{ $param{answers} }) == 0);

   install $pkg;
   
   my $exp_name = $cmd;
   $exp_name =~ s/[^A-Za-z0-9_]+/_/g;
   file "/tmp/expect.$exp_name.tmp",
      content => template('@expect.tpl', __no_sys_info__ => TRUE, %{ $param{options} }, answers => $param{answers}, command => $cmd),
      mode    => 700;

   my $output = run "/tmp/expect.$exp_name.tmp";
   my $ret_val = $?;
   unlink "/tmp/exp_name.$exp_name.tmp";
   $? = $ret_val;

   return $output;
}


=pod

=head1 NAME

Rex::Commands::Expect - A small helper for expect

=head1 DESCRIPTION

This module is a small helper for I<expect>. This module will verify that expect is installed and create and execute an expect script based on the options and answers you have given.

=head1 USAGE

Put it in your I<Rexfile>

 use Rex::Commands::Expect;
     
 task prepare => sub {
     
    expect "passwd",
      options => {
         timeout => 360,
         env     => { LC_ALL => 'C', }
      },
      answers => [
         { 'Enter new UNIX password:' => 'foobar' },
         { 'Retype new UNIX password:' => 'foobar' },
      ];
     
 };

The options parameter is optional. The default for timeout is 360. The return value of I<expect> is stored in I<$?>.

=cut

1;

__DATA__

@expect.tpl
#!/usr/bin/expect --
set timeout <%= $timeout %>
<% for my $e (keys %{ $env }) { %>
set env(<%= $e %>) "<%= $env->{$e} %>"
<% } %>
spawn <%= $command %>
<% for my $exp (@{ $answers }) { %>
<% my ($key) = keys %{ $exp }; %>
expect "<%= $key %>"
send "<%= $exp->{$key} %>\r"
<% } %>
expect eof
@end
