#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::App::OTRS;

use Rex -feature => 0.40;
use Rex::Commands::User;

include qw/Rex::Database::MySQL;
           Rex::Database::MySQL::Admin;
           Rex::Database::MySQL::Admin::User;
           Rex::Database::MySQL::Admin::Schema/;


task test_os => sub {
   if(! is_debian()) {
      die("Currently only debian/ubuntu is supported.");
   }
};

sub install_deps_otrs {

   test_os();

   install [qw/ libcrypt-ssleay-perl
               libgd-gd2-perl
               libencode-hanextra-perl
               libgd-graph-perl
               libjson-xs-perl
               libwww-perl
               libio-socket-ssl-perl
               libmail-imapclient-perl
               libapache-dbi-perl
               libapache2-reload-perl
               libnet-dns-perl
               libnet-smtp-ssl-perl
               libnet-smtp-tls-butmaintained-perl
               libpdf-api2-perl
               libtext-csv-xs-perl
               libxml-parser-perl
               libyaml-perl
               libdbd-mysql-perl
               libnet-ldap-perl
               apache2
                               /];

};

sub install_deps_db {

   install "mysql-server";

};

task setup => sub {
   my $param = shift;

   #### setting defaults
   if(! exists $param->{db})           { $param->{db} = {}; }
   if(! exists $param->{db}->{user})   { $param->{db}->{user} = {}; }
   if(! exists $param->{db}->{schema}) { $param->{db}->{schema} = {}; }

   $param->{version}                   ||= "3.2.3";
   $param->{db}->{create}              ||= FALSE;
   $param->{db}->{user}->{name}        ||= "otrs";
   $param->{db}->{user}->{password}    ||= "otrs";
   $param->{db}->{user}->{rights}      ||= "ALL PRIVILEGES";
   $param->{db}->{user}->{host}        ||= "localhost";
   $param->{db}->{schema}->{host}      ||= "localhost";
   $param->{db}->{schema}->{name}      ||= "otrs";
   #### /defaults

   my $otrs_version = $param->{"version"};

   install_deps_otrs();

   create_user "otrs",
      home    => "/opt/otrs",
      groups  => ["www-data"],
      comment => "OTRS User",
      no_create_home => TRUE;

   deploy($param);
   enable_version($param);

   if(exists $param->{db}->{create} && $param->{db}->{create}) {
      setup_db($param->{db});
   }

};

task setup_db => sub {
   my $param = shift;

   #### setting defaults
   if(! exists $param->{user})   { $param->{user} = {}; }
   if(! exists $param->{schema}) { $param->{schema} = {}; }

   $param->{version}             ||= "3.2.3";
   $param->{user}->{name}        ||= "otrs";
   $param->{user}->{password}    ||= "otrs";
   $param->{user}->{rights}      ||= "ALL PRIVILEGES";
   $param->{user}->{host}        ||= "localhost";
   $param->{schema}->{host}      ||= "localhost";
   $param->{schema}->{name}      ||= "otrs";
   #### /defaults

   my $otrs_version = $param->{"version"};

   install_deps_db();   

   Rex::Database::MySQL::Admin::Schema::create({
      name => $param->{schema}->{name},
   });

   Rex::Database::MySQL::Admin::User::create({
      name => $param->{user}->{name},
      host => $param->{user}->{host},
      password => $param->{user}->{password},
      rights => $param->{user}->{rights},
      schema => $param->{schema}->{name} . ".*",
   });

   for my $file ("otrs-schema.mysql.sql", "otrs-initial_insert.mysql.sql", "otrs-schema-post.mysql.sql") {
      file "/tmp/$file",
         source => "files/db/$otrs_version/$file";

      Rex::Database::MySQL::Admin::execute({
         sql    => "/tmp/$file",
         schema => $param->{schema}->{name},
      });

      unlink "/tmp/$file";
   }
};

task deploy => sub {
   my $param = shift;

   #### setting defaults
   if(! exists $param->{db})           { $param->{db} = {}; }
   if(! exists $param->{db}->{user})   { $param->{db}->{user} = {}; }
   if(! exists $param->{db}->{schema}) { $param->{db}->{schema} = {}; }

   $param->{version}                   ||= "3.2.3";
   $param->{db}->{user}->{name}        ||= "otrs";
   $param->{db}->{user}->{password}    ||= "otrs";
   $param->{db}->{user}->{rights}      ||= "ALL PRIVILEGES";
   $param->{db}->{user}->{host}        ||= "localhost";
   $param->{db}->{schema}->{host}      ||= "localhost";
   $param->{db}->{schema}->{name}      ||= "otrs";
   #### /defaults

   my $otrs_version = $param->{"version"};

   if(!is_file("/tmp/otrs-$otrs_version.tar.gz")) {
      run "wget -O /tmp/otrs-$otrs_version.tar.gz http://ftp.otrs.org/pub/otrs/otrs-$otrs_version.tar.gz";
   }
      
   if(!is_dir("/opt/otrs-$otrs_version/Kernel")) {
      run "tar -xzf /tmp/otrs-$otrs_version.tar.gz -C /opt";
      unlink "/tmp/otrs-$otrs_version.tar.gz";
   }

   chown "otrs", "/opt/otrs-$otrs_version", recursive => TRUE;

   file "/opt/otrs-$otrs_version/Kernel/Config.pm",
      content => template("files/opt/otrs/Kernel/Config.pm.tpl-$otrs_version", db => {
                     host     => $param->{db}->{schema}->{host},
                     schema   => $param->{db}->{schema}->{name},
                     user     => $param->{db}->{user}->{name},
                     password => $param->{db}->{user}->{password},
                  }),
      owner  => "otrs",
      group  => "www-data",
      mode   => 630;

   run "/opt/otrs-$otrs_version/bin/otrs.SetPermissions.pl --otrs-user=otrs --web-user=www-data --otrs-group=www-data --web-group=www-data /opt/otrs-$otrs_version";

};

task enable_version => sub {
   my $param = shift;
   my $otrs_version = $param->{"version"} || "3.2.3";

   cp "/opt/otrs-$otrs_version/scripts/apache2-httpd.include.conf", "/etc/apache2/conf.d";
   ln "/opt/otrs-$otrs_version", "/opt/otrs";

   service apache2 => "restart";

};

1;

=pod

=head1 NAME

Rex::App::OTRS - Deploy OTRS on your Server

=head1 DESCRIPTION

This Rex module will install OTRS and MySQL on your Server. Currently it only supports ubuntu systems. It is tested on an Ubuntu 12.10. Debian may also work.

=head1 USAGE

 require qw/Rex::App::OTRS/;
 set mysql => user => 'root';  # your mysql server credentials
                               # with enough rights to create an otrs schema
                               # and an otrs user
  
 # this task will setup OTRS and its Database on the same host.
 # these settings here are the default options.
 task "setup_otrs", sub {
    Rex::App::OTRS::setup({
      version => "3.2.3",                    # otrs version              (default "3.2.3" if omited)
      db      => {                           # database settings
         create => TRUE,                     # create database           (default "FALSE" if omited)
         user => {                            
            name     => "otrs",              # database user to create   (default "otrs" if omited)
            password => "otrs",              # password for the user     (default "otrs" if omited)
            rights   => "ALL PRIVILEGES",    # privileges for the user   (default "ALL PRIVILEGES" if omited)
            host     => "localhost",         # access host of the user   (default "localhost" if omited)
         },
         schema => {
            name => "otrs",                  # database schema to create (default "otrs" if omited)
            host => "localhost",             # database server where     (default "localhost" if omited)
                                             # otrs should connect to
         }
      }
   });
 };
    
 # this task will setup OTRS but not the database, with all the default options
 task "setup_otrs", sub {
    Rex::App::OTRS::setup();
 };
    
 # this task will setup the database
 task "setup_otrs_database", sub {
    Rex::App::OTRS::setup_db({
      version => "3.2.3",                    # otrs version              (default "3.2.3" if omited)
      user => {
         name     => "otrs",                 # database user to create   (default "otrs" if omited)
         password => "otrs",                 # password for the user     (default "otrs" if omited)
         rights   => "ALL PRIVILEGES",       # privileges for the user   (default "ALL PRIVILEGES" if omited)
         host     => "localhost",            # access host of the user   (default "localhost" if omited)
      },
      schema => {
         name => "otrs",                     # database schema to create (default "otrs" if omited)
      },
    });
 };
     
 # this task will setup the database with all default options
 task "setup_otrs_database", sub {
    Rex::App::OTRS::setup_db();
 };

=head1 Rex/Box

If you want to test OTRS you can use the following Rexfile to setup OTRS in a VirtualBox VM.
After you've created your Rexfile don't forget to run

 rexify --use Rex::App::OTRS

to download the module and its dependencies.

 #
 # (c) Jan Gehring <jan.gehring@gmail.com>
 # 
 # vim: set ts=3 sw=3 tw=0:
 # vim: set expandtab:
 
 # 
 # This Rexfile will install OTRS on a VM
 # After installing OTRS can be used via
 #     http://localhost:8080/otrs/index.pl
 #     User: root@localhost
 #     Pass: root
 #
 # The first time you must login twice
      
 use Rex -feature => 0.40;
     
 use Rex::Commands::User;
 use Rex::Commands::Box;
     
 include qw/Rex::App::OTRS/;
     
 user "root";
 password "box";
 pass_auth;
     
 # set the administrative mysql credentials
 set mysql  => user => 'root';
     
 task "box", sub {
    box {
       my ($box) = @_;
      
       $box->name("otrs01");
       $box->url("http://box.rexify.org/box/ubuntu-server-12.10-amd64.ova");
      
       $box->forward_port(
          ssh  => [2222, 22], # forward port 22 of vm to 2222 of the host system
                              # this is needed for rex
          http => [8080, 80], # forward port 80 of vm to 8080 of the host system
                              # this is needed to access otrs
       );
      
       $box->setup("setup_otrs");
    };
 };
     
 task "prepare", sub {
    # run apt-get update
    update_package_db;
 };
     
 task "setup_otrs", sub {
    prepare();
     
    # install otrs and all of the needed things 
    # like a webserver and mysql
    Rex::App::OTRS::setup({
       version => "3.2.3",
       db      => {
          create => TRUE,
       }
    });
 };


=cut


