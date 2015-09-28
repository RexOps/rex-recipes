#
# AUTHOR: Paco Esteban <paco@onna.be>
# LICENSE: MIT
#
# Simple Module to install and manage Supervisord.

package Rex::System::Supervisord;

use Rex -base;

desc "Installs Supervisord and ensures it runs on boot";
task install => sub {
    pkg "python-setuptools", ensure => 'latest';
    run "easy_install supervisor", sub {
        my ( $stdout, $stderr ) = @_;
        die( "Unable to install supervisor: " . $stderr ) if ( $? != 0 );
    };
    file "/etc/supervisor/conf.d",           ensure => 'directory';
    file "/var/log/supervisor",              ensure => 'directory';
    file "/etc/supervisor/supervisord.conf", source => "files/supervisord.conf";
    file "/etc/systemd/system/supervisord.service",
      source => "files/supervisord.service";
    run "systemctl enable supervisord.service", sub {
        my ( $stdout, $stderr ) = @_;
        die( "I cannot enable systemd service" . $stderr ) if ( $? != 0 );
    };
    service "supervisord", ensure => "started";
};

my @actions = qw( start stop restart reload );
foreach my $action (@actions) {
    desc "$action on supervisord";
    task "$action" => sub {
        service "supervisord" => "$action";
    };
}

desc "Creates a new service";
task service_new => sub {
    my $p = shift;
    if ( !defined( $p->{program_name} ) || !defined( $p->{command} ) ) {
        die("program_name and command are required parameters\n");
    }
    file "/etc/supervisor/conf.d/" . $p->{program_name} . ".conf",
      content =>
      template( "templates/sample_service.conf.tpl", settings => $p ),
      on_change => sub { reload(); };
};

desc "Deletes a service";
task service_delete => sub {
    my $p = shift;
    if ( !defined( $p->{program_name} ) ) {
        die("program_name is mandatory\n");
    }
    file "/etc/supervisor/conf.d/" . $p->{program_name} . ".conf",
      ensure    => 'absent',
      on_change => sub { reload(); };
};

my @service_actions = qw( start stop restart );
foreach my $service_action (@service_actions) {
    desc "$service_action on a service";
    task "service_$service_action" => sub {
        my $p = shift;
        if ( !defined( $p->{program_name} ) ) {
            die("program_name is mandatory\n");
        }
        run "/usr/local/bin/supervisorctl $service_action " . $p->{program_name},
          sub {
            my ( $stdout, $stderr ) = @_;
            die(    "I cannot $service_action on service"
                  . $p->{service} . ": "
                  . $stderr )
              if ( $? != 0 );
          }
    };
}

1;

=pod

=head1 NAME

Rex::System::Supervisord - Installs and configures Supervisord
(http://supervisord.org/)

=head1 DESCRIPTION

Installs and configures Supervisord (http://supervisord.org/)

It uses python easy_install to get the latest version, as some packaged sources are too
old.

It's only beeen tested on debian8. It should work on Red Hat derived systems.

=head1 USAGE

 include qw/Rex::System::Supervisord/;

 task yourtask => sub {
    Rex::System::Supervisord::service_new(
        program_name => 'my_program',
        command => '/usr/local/bin/my_command',
        user => 'foo',
        # ... 
    );
 };

You can also use this from command line, passing parameters to the task.

=head1 TASKS

=over 4

=item install

It just installs Supervisor. Uses easy_install to get lat version.
It configures startup launch using systemd.

=item uninstall

=item start, stop, restart, reload

Take those actions on supervisord process.

=item service_start service_stop service_restart

Take those actions on a service.

  --program_name=my_program

is mandatory.

=item service_new

Creates a new service.
All parameters passed to the task are expanded on a key=value manner on config file.
Check http://supervisord.org/configuration.html#program-x-section-settings for details.

=item service_delete

Deletes a service

  --program_name=my_program

is mandatory.

=back

=cut
