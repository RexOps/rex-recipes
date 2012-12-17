#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Database::MySQL::Admin;
   
use strict;
use warnings;

use Rex -base;
use Rex::Logger;
use Rex::Config;
use Rex::Database::MySQL::Admin::Schema;
use Rex::Database::MySQL::Admin::User;

my %MYSQL_CONF = ();

Rex::Config->register_set_handler("mysql" => sub {
   my ($name, $value) = @_;
   $MYSQL_CONF{$name} = $value;
});

task execute => sub {

   my $param = shift;
   die("You have to specify the sql to execute.") unless $param->{sql};

   my $sql = $param->{sql};

   my $tmp_file = _tmp_file();

   Rex::Logger::debug("Executing: $sql");

   file $tmp_file,
      content => $sql;

   my $user     = $MYSQL_CONF{user};
   my $password = $MYSQL_CONF{password} || "";

   unless($password) {
      say run "mysql -u$user < $tmp_file";
   }
   else {
      say run "mysql -u$user -p$password < $tmp_file";
   }

   unlink($tmp_file);

   if($? != 0) {
      die("Error executing $sql");
   }
};

sub _tmp_file {
   return "/tmp/" . rand(100) . ".sql";
}

1;

=pod

=head1 NAME

Rex::Database::MySQL::Admin - Manage your MySQL Server

=head1 USAGE

 set mysql => user => 'root';
 set mysql => password => 'foobar';
   

