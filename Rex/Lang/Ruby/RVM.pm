package Rex::Lang::Ruby::RVM;

use Rex -base;

=pod

=head1 NAME

Rex::Lang::Ruby::RVM - Ruby RVM module for Rex

=head1 DESCRIPTION

This module helps managing RVM.

=head1 USAGE

=head2 Without importing tasks

 include Rex::Lang::Ruby::RVM;

 task 'yourtask', sub {
     Rex::Lang::Ruby::RVM::setup();
 };

=head2 With importing tasks

 require Rex::Lang::Ruby::RVM;

Then call its tasks like this:

 rex -H $HOST Lang:Ruby:RVM:setup;

=head1 TASKS

=over 4

=item setup

Installs RVM. Usage:

 Rex::Lang::Ruby::RVM::setup(
     action => 'stable',
     ruby   => '2.1.2',
     gems   => 'bundler',
 );

All parameters are optional.

=over 8

=item action: upstream RVM branch to install

master or stable (default is master)

=item ruby: ruby version to install

You can use undef to install latest stable ruby version, or provide a comma-separated list of multiple versions

=item gems: comma-separated list of gems to install

=back

=cut

desc 'Install RVM';
task 'setup', sub {
    my $param   = shift;
    my $command = 'curl -sSL https://get.rvm.io | bash';

    $command .= ' -s ';
    $command .= defined $param->{action}
        && $param->{action} eq 'stable' ? 'stable' : '--';

    if ( exists $param->{ruby} ) {
        $command .= ' --ruby';
        $command .= defined $param->{ruby} ? "=$param->{ruby}" : '';
    }

    if ( defined $param->{gems} ) {
        $command .= " --gems=$param->{gems}";
    }

    pkg 'curl', ensure => 'present';

    run $command;
};

1;

=back

=cut
