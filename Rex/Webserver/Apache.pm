#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES: 
# LICENSE: Apache License 2.0
# 
# Simple Module to install Apache on your Server.

package Rex::Webserver::Apache;


use Rex -base;

# some package-wide variables

our %package = (
   Debian => "apache2",
   Ubuntu => "apache2",
   CentOS => "httpd",
   Mageia => "apache-base",
);

our %service_name = (
   Debian => "apache2",
   Ubuntu => "apache2",
   CentOS => "httpd",
   Mageia => "httpd",
);

our %document_root = (
   Debian => "/var/www",
   Ubuntu => "/var/www",
   CentOS => "/var/www/html",
   Mageia => "/var/www/html",
);

task "setup", sub {

   my $pkg     = $package{get_operating_system()};
   my $service = $service_name{get_operating_system()};

   # install apache package
   update_package_db;
   install package => $pkg;

   # ensure that apache is started
   service $service => "ensure" => "started";

};

task "start", sub {

   my $service = $service_name{get_operating_system()};
   service $service => "start";

};

task "stop", sub {

   my $service = $service_name{get_operating_system()};
   service $service => "stop";

};

task "restart", sub {

   my $service = $service_name{get_operating_system()};
   service $service => "restart";

};

task "reload", sub {

   my $service = $service_name{get_operating_system()};
   service $service => "reload";

};

1;

=pod

=head2 Module to install Apache

This module installs apache webserver.

=head2 USAGE

Put it in your I<Rexfile>

 # your tasks
 task "one", sub {};
 task "two", sub {};
    
 require Rex::Webserver::Apache;

And call it:

 rex -H $host Webserver:Apache:setup

Or, to use it as a library

 task "yourtask", sub {
    Webserver::Apache::setup();
 };
   
 require Rex::Webserver::Apache;

=head2 TASKS

=over 4

=item setup

This task will install apache httpd.

=item start

This task will start the apache daemon.

=item stop

This task will stop the apache daemon.

=item restart

This task will restart the apache daemon.

=item reload

This task will reload the apache daemon.

=back

=cut

