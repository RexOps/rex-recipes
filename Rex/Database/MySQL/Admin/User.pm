#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Database::MySQL::Admin::User;
   
use strict;
use warnings;

use Rex -base;
use Rex::Database::MySQL::Admin;

task create => sub {

   my $param = shift;
   die("You have to specify the user name.") unless $param->{name};
   die("You have to specify the users host.") unless $param->{host};
   die("You have to specify the users password.") unless $param->{password};
   die("You have to specify the users rights.") unless $param->{rights};
   die("You have to specify the users schemas.") unless $param->{schema};

   my $name     = $param->{name};
   my $host     = $param->{host};
   my $password = $param->{password};
   my $rights   = $param->{rights};
   my $schema   = $param->{schema};

   Rex::Database::MySQL::Admin::execute({sql => "GRANT $rights ON $schema TO '$name'\@'$host' IDENTIFIED BY '$password';\nFLUSH PRIVILEGES;\n"});

};

task drop => sub {

   my $param = shift;
   die("You have to specify the user name.") unless $param->{name};
   die("You have to specify the users host.") unless $param->{host};

   my $name      = $param->{name};
   my $host      = $param->{host};
   my $deleteall = $param->{delete_all};

   if ($deleteall) {
      Rex::Database::MySQL::Admin::execute({sql => "DELETE FROM mysql.user WHERE USER LIKE '$name';\nFLUSH PRIVILEGES;\n"});
   } else {
      Rex::Database::MySQL::Admin::execute({sql => "DROP USER '$name'\@'$host';\nFLUSH PRIVILEGES;\n"});
   }

};



1;

=pod

=head1 NAME

Rex::Database::MySQL::Admin::User - Managa MySQL User

=head1 USAGE

 task "taskname", sub {
    Rex::Database::MySQL::Admin::User::create({
       name     => "foo",
       host     => "host",
       password => "password",
       rights   => "SELECT,INSERT",
       schema   => "foo.*",
    });
     
    Rex::Database::MySQL::Admin::User::drop({
       name       => "foo",
       host       => "host",
       delete_all => "if empty not executed",
    });
 };

