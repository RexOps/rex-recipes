package Rex::Lang::Ruby::Gem;

use Rex -base;

=pod

=head1 NAME

Rex::Lang::Ruby::Gem - Ruby gem managing module for Rex

=head1 DESCRIPTION

This module helps managing Ruby gems.

=head1 USAGE

=head2 Without importing tasks

 include Rex::Lang::Ruby::Gem;

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

    die 'You must specify a gem to install!' unless $param->{name};

    my $command = "gem install $param->{name}";
    $command .= " --version '$param->{version}'" if defined $param->{version};

    run $command;
};

1;

=back

=cut
