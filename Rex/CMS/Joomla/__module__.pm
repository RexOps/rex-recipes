#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: Webserver::Apache, Database::MySQL
# LICENSE: Apache License 2.0
# COMPAT: 0.26
# 
# Module to install Joomla on your Server. 
# Tested with Joomla 2.5.1 and Ubuntu.

package Rex::CMS::Joomla;


use Rex -base;

include qw/
   Rex::Webserver::Apache
   Rex::Database::MySQL
   Rex::Database::MySQL::Admin
   Rex::Database::MySQL::Admin::Schema
   Rex::Database::MySQL::Admin::User
   Rex::Lang::PHP
   Rex::Lang::PHP::Module/;

my %JOOMLA_CONF = ();

Rex::Config->register_set_handler("joomla" => sub {
   my ($name, $value) = @_;
   $JOOMLA_CONF{$name} = $value;
});


task prepare => sub {

   my $param = shift;

   my $document_root = $Rex::Webserver::Apache::document_root{get_operating_system()};

   # we need unzip and wget
   install "unzip";
   install "wget";

   # install apache and php
   Rex::Webserver::Apache::setup();

   Rex::Database::MySQL::setup();

   Rex::Lang::PHP::setup();
   Rex::Lang::PHP::Module::setup({
      name => "mysql",
   });
   
   # clean up documentroot
   rm "/var/www/index.html";

   my $url = $JOOMLA_CONF{url};
   $url ||= "http://joomlacode.org/gf/download/frsrelease/16760/72877/Joomla_2.5.2-Stable-Full_Package.zip";

   my $file = [ split /\//, $url ]->[-1];

   # download joomla
   run "cd $document_root; wget $url";

   # extract package
   extract $file,
      chdir => $document_root;

   service apache2 => "restart";
};

task config => sub {

   my $param = shift;

   die("You have to set the sitename.") unless($param->{sitename});

   my $sitename    = $param->{sitename};
   my $db_user     = $param->{dbuser} || "joomla";
   my $db_password = $param->{dbpassword} || rand(100);
   my $db_name     = $param->{db} || "joomla";

   my $joomla_admin    = $param->{joomlaadmin} || "admin";
   my $joomla_password = $param->{joomlapassword} || get_random(8, 'a' .. 'z');
   my $joomla_email    = $param->{joomlaemail} || "foo\@bar.tld";

   my $document_root = $Rex::Webserver::Apache::document_root{get_operating_system()};

   # config file
   cp "$document_root/installation/configuration.php-dist", "$document_root/configuration.php";

   sed qr{sitename = 'Joomla!'}, "sitename = '$sitename'", "$document_root/configuration.php";
   sed qr{user = ''}, "user = '$db_user'", "$document_root/configuration.php";
   sed qr{password = ''}, "password = '$db_password'", "$document_root/configuration.php";
   sed qr{db = ''}, "db = '$db_name'", "$document_root/configuration.php";

   delete_lines_matching "$document_root/configuration.php", matching => qr{root_user};

   my $secret = get_random(16, 'a' .. 'z');
   sed qr{secret = '(.*?)'}, "secret = '$secret'", "$document_root/configuration.php";

   mkdir "$document_root/logs",
      mode => 777;
   sed qr{log_path = '(.*?)'}, "log_path = '$document_root/logs'", "$document_root/configuration.php";

   if($param->{drop}) {
      # maybe not existend yet
      eval {
         Rex::Database::MySQL::Admin::User::drop({
            name => $db_user,
            host => 'localhost',
         });
      };

      eval {
         Rex::Database::MySQL::Admin::Schema::drop({
            name => $db_name,
         });
      };
   }

   Rex::Database::MySQL::Admin::Schema::create({
      name => $db_name,
   });

   Rex::Database::MySQL::Admin::User::create({
      name     => $db_user,
      host     => 'localhost',
      password => $db_password,
      rights   => "ALL PRIVILEGES",
      schema   => "$db_name.*",
   });

   my $content = "use $db_name;\n\n" . cat "$document_root/installation/sql/mysql/joomla.sql";
   $content =~ s/`#__/`jos_/gms;

   Rex::Database::MySQL::Admin::execute({
      sql => $content,
   });

   file "$document_root/gen_pw.php",
      content => q~<?php
define('JPATH_PLATFORM', 1);
include "libraries/joomla/user/helper.php";
$salt = JUserHelper::genRandomPassword(32);
$crypt = JUserHelper::getCryptedPassword("~ . $joomla_password . q~", $salt);
$cryptpass = $crypt.':'.$salt;
print $cryptpass . "\n";
   ~;

   my $cryptpass = run "php $document_root/gen_pw.php";
   rm "$document_root/gen_pw.php";

   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
   $year += 1900;
   $mon += 1;

   $mon  = sprintf("%02i", $mon);
   $mday = sprintf("%02i", $mday);
   $hour = sprintf("%02i", $hour);
   $min  = sprintf("%02i", $min);

   my $now = "$year-$mon-$mday $hour:$min:$sec";
   my $root_uid = int(rand(int(100)));

   Rex::Database::MySQL::Admin::execute({
      sql => "INSERT INTO `$db_name`.`jos_users` VALUES ($root_uid,'Super User','$joomla_admin','$joomla_email','$cryptpass','deprecated',0,1,'$now','$now','0','');",
   });

   Rex::Database::MySQL::Admin::execute({
      sql => "INSERT INTO `$db_name`.`jos_user_usergroup_map` VALUES ($root_uid,8);",
   });

   say "Admin-User: $joomla_admin";
   say "Admin-Password: $joomla_password";

   rmdir "$document_root/installation";

};

1;

=pod

=head2 Module to install Joomla

This module installs joomla cms on your server.

=head2 USAGE

Put it in your I<Rexfile>

 include qw/Rex::CMS::Joomla/;
  
 set mysql => user => 'root';
  
 task joomla => sub {
    Rex::CMS::Joomla::prepare();
    Rex::CMS::Joomla::config({
       sitename => "rex",
    });
 };

