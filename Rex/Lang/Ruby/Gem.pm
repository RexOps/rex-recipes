package Rex::Lang::Ruby::Gem;

use Rex -base;

require Exporter;
use base qw(Exporter);
use vars qw (@EXPORT);

@EXPORT = qw(gem);

=pod

=head1 NAME

Rex::Lang::Ruby::Gem - Ruby gem managing module for Rex

=head1 DESCRIPTION

This module helps managing Ruby gems.

=head1 USAGE

=head2 Without importing tasks

 include qw/Rex::Lang::Ruby::Gem/;

 task 'yourtask', sub {
     Rex::Lang::Ruby::Gem::setup(
         name    => 'gemname',
         version => 'gemversion',
     );
 };

=head2 With importing tasks

 require Rex::Lang::Ruby::Gem;

Then call its tasks like this:

 rex -H $HOST Lang:Ruby:Gem:setup --name='gemname' --version='gemversion'

=head1 TASKS

=over 4

=item setup

Installs arbitrary gem

 task 'yourtask', sub {
     # long version
     Rex::Lang::Ruby::Gem::setup(
         name    => 'gemname',
         version => 'gemversion',
     );
 };

Parameters:

=over 8

=item name (required): gem to install

=item version: gem version to install

=back

=cut

desc 'Install arbitrary gem';
task 'setup', sub {
  my $param = shift;
  gem( $param->{name}, ensure => $param->{version} );
};

=item gem($name, %option)

gem() is an exported resource that can be used as a shortcut to manage your gems.

 gem 'gemname';
 gem 'gemname', ensure => 'gemversion';
 gem 'gemname', ensure => 'installed';
 gem 'gemname', ensure => 'present';
 gem 'gemname', ensure => 'absent';
 gem 'gemname', ensure => 'latest';

=cut

sub gem {
  my ( $name, %option ) = @_;

  die 'You must specify a gem to install!' unless $name;

  my $ensure  = $option{ensure};
  my $version = $option{version} || undef;
  my $command = "gem ";

  if ( $ensure eq 'latest' ) {
    $version = undef;    # just install the newest version
  }

  if ( $ensure eq 'absent' ) {
    $command .= "uninstall ";
    $version = undef;
    Rex::Logger::info( "Ensuring gem $name "
        . ( exists $option{version} ? $option{version} : "" )
        . " to be absent " );
  }
  elsif ( $ensure eq 'present' || $ensure eq 'installed' ) {
    if ( defined $version ) {
      my ($found) = grep { m/^$name\s/ } run "gem list";
      if ($found) {
        Rex::Logger::info("Gem already installed ($found).");
        return;
      }
    }

    $command .= "install ";
    Rex::Logger::info( "Ensuring gem $name to be "
        . ( exists $option{version} ? $option{version} : $ensure ) );
  }

  $command .= $name;

  $command .= " --version '$version'" if defined $version;

  run $command;
}

1;

=back

=cut
