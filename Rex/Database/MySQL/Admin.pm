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

   my ($tmp_file, $delete);

   if(is_file($param->{sql})) {
      $tmp_file = $param->{sql};
   }
   else {
      $tmp_file = _tmp_file();
      $delete = 1;

      file $tmp_file,
         content => $sql;
   }

   Rex::Logger::debug("Executing: $sql");

   my $user          = $MYSQL_CONF{user};
   my $password      = $MYSQL_CONF{password} || "";
   my $defaults_file = $MYSQL_CONF{defaults_file} || "";
   my $schema        = $param->{schema} || "";

   my $result;

   if ($defaults_file) {
      $result = run "mysql --defaults-file=$defaults_file $schema < $tmp_file";
   }
   elsif ($password) {
      $result = run "mysql -u$user -p$password $schema < $tmp_file";
   }
   else {
      $result = run "mysql -u$user $schema < $tmp_file";
   }

   say $result unless $param->{quiet};

   if($? != 0) {
      die("Error executing $sql");
   }
   
   unlink($tmp_file) if $delete;

   return $result;
};

task mysqladmin => sub {

   my $param = shift;
   die("You have to specify the mysqladmin command to execute.") unless $param->{command};

   my $user          = $MYSQL_CONF{user};
   my $password      = $MYSQL_CONF{password} || "";
   my $defaults_file = $MYSQL_CONF{defaults_file} || "";

   my $result;

   if ($defaults_file) {
      $result = run "mysqladmin --defaults-file=$defaults_file $param->{command}";
   }
   elsif ($password) {
      $result = run "mysqladmin -u$user -p$password $param->{command}";
   }
   else {
      $result = run "mysqladmin -u$user $param->{command}";
   }

   return $result;
};

sub get_variable {

   my $var = shift;

   return undef unless $var;

   my $variables = mysqladmin( { command => 'variables' });

   return undef unless $variables; # error

   if ($variables =~ /^\| $var\s+\| (\w+)\s+\|/m) {

      return $1;
   }
   else {
      return '';
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

or

 set mysql => defaults_file => '/etc/mysql/debian.cnf';
  
 task mysql_status, sub {
 
    my $status = Rex::Database::MySQL::Admin::mysqladmin({ command => 'status' });
 
    say "STATUS: $status";
 };

