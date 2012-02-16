#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Database::MySQL::Admin::User;
   
use strict;
use warnings;

use Rex -base;
use Database::MySQL::Admin;

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

   Database::MySQL::Admin::execute({sql => "GRANT $rights ON $schema TO '$name'\@'$host' IDENTIFIED BY '$password';\nFLUSH PRIVILEGES;\n"});

};

task drop => sub {

   my $param = shift;
   die("You have to specify the user name.") unless $param->{name};
   die("You have to specify the users host.") unless $param->{host};
   die("You have to specify the users rights.") unless $param->{rights};
   die("You have to specify the users schemas.") unless $param->{schema};

   my $name     = $param->{name};
   my $host     = $param->{host};

   Database::MySQL::Admin::execute({sql => "DROP USER '$name'\@'$host';\nFLUSH PRIVILEGES;\n"});

};



1;

=pod

=head2 Managa a Schema

This module allows you to manage your MySQL Schemas.

=head2 USAGE

 task "taskname", sub {
    Database::MySQL::Admin::Schema::create({
       name => "foo",
    });
 };

