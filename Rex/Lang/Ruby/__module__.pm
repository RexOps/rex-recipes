package Rex::Lang::Ruby;

use Rex -base;

=pod

=head1 NAME

Rex::Lang::Ruby - Ruby language module for Rex

=head1 DESCRIPTION

This module helps managing tasks related to the Ruby language.

=head1 USAGE

=head2 Without importing tasks

 include qw/Rex::Lang::Ruby/;

 task 'yourtask', sub {
     Rex::Lang::Ruby::setup();
 };

=head2 With importing tasks

 require Rex::Lang::Ruby;

Then call its tasks like this:

 rex -H $HOST Rex:Lang:Ruby:setup

=head1 TASKS

=over 4

=item setup

Installs ruby via default package manager

=cut

desc 'Install ruby via default package manager';
task 'setup', sub {
    pkg 'ruby', ensure => 'present';
};

=item setup_from_source

Installs ruby from source. Usage:

 Rex::Lang::Ruby::setup_from_source( version => '2.1.2' );

Parameters:

=over 8

=item version (required): Ruby version to install

=back

=cut

desc 'Install ruby from source';
task 'setup_from_source', sub {
    my $params = shift;

    die 'You must specify a ruby version to install!'
        unless $params->{version};

    my $packages = [qw(gcc make)];
    my $additional_packages = case operating_system, {
        qr{centos|fedora|redhat}i => [qw(openssl-devel zlib-devel)],
            qr{debian|ubuntu}i    => [qw(libssl-dev zlib1g-dev)],
    };

    push @{$packages}, @{$additional_packages};

    pkg $packages, ensure => 'present';

    my $ruby_site     = 'http://cache.ruby-lang.org/pub/ruby';
    my $ruby_version  = "ruby-$params->{version}";
    my $ruby_filename = "$ruby_version.tar.bz2";
    my $tmp_dir       = Rex::Config->get_tmp_dir();

    run "wget $ruby_site/$ruby_filename", cwd => "$tmp_dir";
    extract( File::Spec->join( $tmp_dir, $ruby_filename ), to => "$tmp_dir" );
    run './configure && make && make install',
        cwd => File::Spec->join( $tmp_dir, $ruby_version );
};

1;

=back

=cut
