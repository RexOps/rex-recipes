#
# AUTHOR: Paco Esteban <paco@onna.be>
# LICENSE: MIT
#
# Simple Module to install and manage duplicity (http://duplicity.nongnu.org/)

package Rex::System::Duplicity;

use strict;
use warnings;
use Rex -base;
use Rex::Logger;

my $conf = get "duplicity";

desc "Installs duplicity from launchpad tarball";
task install => sub {
    my @required_pkg
      = qw/curl python python-setuptools librsync1 gnupg python-lockfile python-paramiko python-pycryptopp python-boto python-dev librsync-dev/;
    my ($src_file) = $conf->{source} =~ m/.*\/(duplicity-.*\.tar\.gz)/;

    foreach my $p (@required_pkg) {
        pkg $p, ensure => "latest";
    }

    _get_package( $conf->{source}, "/tmp/" . $src_file );
    extract "/tmp/" . $src_file, to => "/tmp/";

    run "cd /tmp/duplicity*; python setup.py install", sub {
        my ( $stdout, $stderr ) = @_;
        my $server = Rex::get_current_connection()->{server};
        Rex::Logger::debug("[$server] $stdout");
        Rex::Logger::debug("[$server] $stderr");
    };
    run "rm -rf /tmp/duplicity*";
};

desc "configures a cronjob to launch duplicity backups";
task configure => sub {
    my $envs;
    foreach my $e ( keys %{ $conf->{env} } ) {
        $envs .= uc($e) . "='" . $conf->{env}->{$e} . "' ";
    }

    foreach my $j ( @{ $conf->{jobs} } ) {
        cron_entry "duplicity",
          ensure => "present",
          command =>
          "$envs /usr/local/bin/duplicity $j->{options} $j->{orig} $j->{dest}",
          minute       => $j->{time}->{minute},
          hour         => $j->{time}->{hour},
          month        => $j->{time}->{month},
          day_of_week  => $j->{time}->{"day-of-week"},
          day_of_month => $j->{time}->{"day-of-month"},
          user         => $j->{user},
          on_change    => sub { say "Duplicity backup cron added"; };
    }
};

sub _get_package {
    my ( $url, $destfile, %params ) = @_;
    run "Downloading",
      command => "curl -# -L -k " . $url . " > " . $destfile . " 2> /dev/null",
      unless  => "[ -f " . $destfile . " ]";

    if ( $params{sha1} ) {
        run "echo '"
          . $params{sha1} . " "
          . $destfile
          . "' | sha1sum --check --status", sub {
            my ( $stdout, $stderr ) = @_;
            if ( $? != 0 ) {
                my $server = Rex::get_current_connection()->{server};
                Rex::Logger::info("$stdout")        if ($stdout);
                Rex::Logger::info("$stderr", 'error') if ($stderr);
                die "Checksum does not match for downloaded file !";
            }
          }
    }
}


1;

=pod

=head1 NAME

Rex::System::Duplicity - installs duplicity and configures cron if needed

=head1 DESCRIPTION

Installs duplicity (http://duplicity.nongnu.org/duplicity.1.html) and configures a cron job to perform backups if needed.
It uses last launchpad tarball.

The config for the cronjobs must be inserted on a config file.

=head1 USAGE

 include qw/Rex::System::Duplicity/;

 task yourtask => sub {
    Rex::System::Duplicity::install();
    Rex::System::Duplicity::configure();
 };

=head1 TASKS

=over 4

=item install

Just installs duplicity and its dependencies.
Should run on debian and derivatives. Not tested on other systems, but can be easily adapted.

=back

=item configure

Sets upo a cron job and sets up the environment variables if needed.
Configuration should provide the needed env variables in the  duplicity section.
In the example the passphrase and AWS credentials. Check duplicity(1) man page for details.
Mind that the recipe will upercase all the env variables.
Also in this section you can add as many cront jobs as you want. Like this:

 set duplicity => {
     source => "https://launchpad.net/duplicity/0.7-series/0.7.10/+download/duplicity-0.7.10.tar.gz",
     env => {
         aws_access_key_id => "YOUR ID",
         aws_secret_access_key => "YOUR KEY",
         passphrase => "GPG PASSPHRASE",
     },
     jobs => [
         {
             user => "root",
             options => "full --s3-european-buckets --s3-use-new-style",
             orig => "/tmp/foo",
             dest => "s3+http =>//mybucket/test",
             time => {
                 minute => 0,
                 hour => 0,
                 month => "*",
                 "day-of-week" => 1,
                 "day-of-month" => "*",
             }
         },
     ],
 }

=back

=cut
