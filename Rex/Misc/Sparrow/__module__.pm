package Rex::Misc::Sparrow;

use strict;
use warnings;

use Rex -base => [qw(1.4 exec_autodie)];
use Rex::CMDB;

use Rex::Lang::Perl::Cpanm;

use File::Spec;
use YAML;

our $sparrow = get cmdb 'sparrow';

unless ( defined $sparrow ) {
  my $yaml =
    YAML::LoadFile( Rex::Helper::Path::get_file_path('files/sparrow.yml') );
  $sparrow = $yaml->{sparrow};
}

our $sparrow_temp = File::Spec->tmpdir();

=pod

=head1 NAME

Rex::Misc::Sparrow - manage and run sparrow checks

=head1 DESCRIPTION

Setup sparrow and its checks described in the configuration file, and run them.

=head1 USAGE

 $ rexify --use=Rex::Misc::Sparrow
 $ rex Misc:Sparrow:setup

=head1 TASKS

=over 4

=item setup

Installs sparrow plugin via cpanm, and configures checks.

=cut

desc 'Setup sparrow';
task 'setup', sub {
  cpanm -install;
  cpanm -install => [qw(Digest::MD5 Test::More Sparrow~0.0.21)];

  needs 'configure';
};

=item configure

Installs and configures sparrow checks as described in either CMDB or in C<files/sparrow.yml>.

=cut

desc 'Configure sparrow checks';
task 'configure', sub {
  run 'sparrow index update';

  foreach my $project ( keys %{$sparrow} ) {
    run "sparrow project create $project";

    foreach my $check ( @{ $sparrow->{$project} } ) {
      run "sparrow plg install $check->{plugin}";
      run "sparrow check add $project $check->{checkname}";
      run "sparrow check set $project $check->{checkname} $check->{plugin}";
      configure_check( $project, $check );
      run "sparrow check show $project $check->{checkname}";
    }
  }
};

=item check

Runs configured sparrow checks.

 $ rex -qw Misc:Sparrow:check

=cut

desc 'Runs sparrow checks';
task 'check', sub {
  foreach my $project ( keys %{$sparrow} ) {
    foreach my $check ( @{ $sparrow->{$project} } ) {
      say scalar run "sparrow check run $project $check->{checkname}";
    }
  }
};

=back

=head1 SUBROUTINES

=over 4

=item configure_check( $project, $check )

Configure a sparrow check. C<$check> is the full data structure from CMDB or  C<sparrow.yml>.

=cut

sub configure_check {
  my ( $project, $check ) = @_;

  my $config_file = my $default_config =
    File::Spec->join( '~', 'sparrow', 'plugins', 'public', $check->{plugin},
    'suite.ini' );
  my $temp_config;

  if ( exists $check->{settings} ) {
    $temp_config =
      File::Spec->join( $sparrow_temp,
      'sparrow-' . $check->{checkname} . '.ini' );

    cp $default_config, $temp_config;
    chmod 700, $temp_config;

    while ( my ( $key, $value ) = each %{ $check->{settings} } ) {
      sed qr{\b$key\b = .*}, join( ' = ', $key, $value ), $temp_config;
    }

    $config_file = $temp_config;
  }

  run "sparrow check load_ini $project $check->{checkname} $config_file";

  file $temp_config, ensure => 'absent';
}

=back

=head1 See also

https://sparrowhub.org

=cut 

1;
