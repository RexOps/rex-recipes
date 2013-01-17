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

our %vhost_path = (
   Debian => "/etc/apache2/sites-enabled",
   Ubuntu => "/etc/apache2/sites-enabled",
   CentOS => "/etc/httpd/conf.d",
   Mageia => "/etc/httpd/conf.d",
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

task "vhost", sub {
   
   my $param = shift;

   file $vhost_path{get_operating_system()} . "/" . $param->{name} . ".conf",
      content => $param->{conf},
      owner   => "root",
      group   => "root",
      mode    => 644,
      on_change => sub {
         service $service_name{get_operating_system()} => "restart";
      };

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

=head1 NAME

Rex::Webserver::Apache - Module to install Apache

=head1 USAGE

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

=head1 TASKS

=over 4

=item setup

This task will install apache httpd.

=item vhost

This task will create a vhost.

 task "yourtask", sub {
    Rex::Webserver::Apache::vhost({
      name => "foo",
      conf => template("files/foo.conf"),
    });
 };

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

