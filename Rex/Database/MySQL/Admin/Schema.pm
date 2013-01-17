#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Database::MySQL::Admin::Schema;
   
use strict;
use warnings;

use Rex -base;
use Rex::Database::MySQL::Admin;

task create => sub {

   my $param = shift;
   die("You have to specify the schema name.") unless $param->{name};

   my $db = $param->{name};

   Rex::Database::MySQL::Admin::execute({sql => "CREATE SCHEMA IF NOT EXISTS `$db`;\n"});

};

task drop => sub {

   my $param = shift;
   die("You have to specify the schema name.") unless $param->{name};

   my $db = $param->{name};

   Rex::Database::MySQL::Admin::execute({sql => "DROP SCHEMA `$db`;\n"});

};



1;

=pod

=head1 NAME

Rex::Database::MySQL::Admin::Schema - Managa a Schema

=head1 USAGE

 task "taskname", sub {
    Rex::Database::MySQL::Admin::Schema::create({
       name => "foo",
    });
 };

=head1 MODULE FUNCTIONS

=over 4

=item create({name => $schema_name})

Create a new Database Schema.

 Rex::Database::MySQL::Admin::Schema::create({
    name => "foobar",
 });

=item drop({name => $schema_name})

Drop a Database Schema.

 Rex::Database::MySQL::Admin::Schema::drop({
    name => "foobar",
 });

=back

=cut

