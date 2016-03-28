package Rex::Misc::Sparrow;

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

  # maybe using $HOME is better? I'm not sure how sensitive the config can be
  my $tmpdir = File::Spec->tmpdir();

  run 'sparrow index update';

  foreach my $project ( keys %{$sparrow} ) {
    run "sparrow project create $project";

    foreach my $check ( @{ $sparrow->{$project} } ) {
      run "sparrow plg install $check->{plugin}";

      run "sparrow check add $project $check->{checkname}";

      run "sparrow check set $project $check->{checkname} $check->{plugin}";

      my $config_file =
        File::Spec->join( $tmpdir, 'sparrow-' . $check->{checkname} . '.ini' );

      file $config_file,
        content => template( '@suite.ini.tpl', check => $check );

      run "sparrow check load_ini $project $check->{checkname} $config_file";
      run "sparrow check show $project $check->{checkname}";

      rm $config_file;
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
      say scalar run 'sparrow check run system disk';
    }
  }
};

1;

=back

=head1 See also

https://sparrowhub.org

=cut 

__DATA__

@suite.ini.tpl
[<%= $check->{checkname} %>]
<% while ( my ($key, $value) = each %{$check->{settings}} ) { -%>
<%= $key %> = <%= $value %>
<% } %>
