#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Database::MySQL::Admin::Schema;
   
use strict;
use warnings;

use Rex -base;
use Database::MySQL::Admin;

task create => sub {

   my $param = shift;
   die("You have to specify the schema name.") unless $param->{name};

   my $db = $param->{name};

   Database::MySQL::Admin::execute({sql => "CREATE SCHEMA `$db`;\n"});

};

task drop => sub {

   my $param = shift;
   die("You have to specify the schema name.") unless $param->{name};

   my $db = $param->{name};

   Database::MySQL::Admin::execute({sql => "DROP SCHEMA `$db`;\n"});

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

=head2 MODULE FUNCTIONS

=over 4

=item create({name => $schema_name})

Create a new Database Schema.

 Database::MySQL::Admin::Schema::create({
    name => "foobar",
 });

=item drop({name => $schema_name})

Drop a Database Schema.

 Database::MySQL::Admin::Schema::drop({
    name => "foobar",
 });

=back

=cut

