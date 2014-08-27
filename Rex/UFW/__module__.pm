#
# Nicolas Leclercq <nicolas.private@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::UFW;

use Rex -base;

use Rex::Ext::TemplateToolkit;

task setup => sub {

  Rex::Logger::info("Installing UFW");
  pkg "ufw", ensure => "latest";
};

task enable => sub {

  Rex::Logger::info("Enabling UFW rules");
  run "ufw --force enable";
};

task disable => sub {

  Rex::Logger::info("Disabling UFW rules");
  run "ufw disable";
};

sub allow {
  my ($data) = @_;

  if ( $data->{application} ) {
    Rex::Logger::info("Adding UFW $data->{application} rules");
    run "ufw allow $data->{application}";
  }
};

task allow => allow;

task forbid => sub {
  my ($data) = @_;

  if ( $data->{application} ) {
    Rex::Logger::info("Removind UFW $data->{application} rules");
    run "ufw delete allow $data->{application}";
  }
};

task application => sub {
  my ($data) = @_;

  return unless defined $data->{application} and defined $data->{ports};

  $data->{title}       = $data->{application} unless defined $data->{title};
  $data->{description} = $data->{application} unless defined $data->{description};

  file "/etc/ufw/applications.d/$data->{application}",
    content => template_toolkit( "templates/etc/ufw/applications.d/application.tpl", $data ),
    owner   => "root",
    group   => "root",
    mode    => 644;

  allow $data;
};

=pod

=head1 NAME

Rex::UFW - Simple interface to UFW

=head1 DESCRIPTION

Simple interface to create, allow and fordib ufw application rules.

=head1 USAGE

 use Rex::UFW;

 task "allow_ssh", sub {

  # install ufw package
  Rex::UFW::setup();

  # Allow SSH, on ubuntu /etc/ufw/application.d/openssh-server is bundle with deb package
   Rex::UFW::allow({
     application => 'OpenSSH'
   });

   # Enable UFW
   Rex::UFW::enable();
 };

 task "irc_server", sub {

  # ... do stuff

  # add new ufw application
  Rex::UFW::application({
    name => 'ngIRCd',
    title => 'ngircd daemon'
    description => 'ngircd daemon',
    ports => [ qw(6667/tcp) ]
  });
 };

=head1 METHODS

You can use the following methods to control UFW behavior.

=over 4

=item setup

 Install ufw package

 task t => sub {
   Rex::UFW::setup();
 };

=item enable

 Enable UFW, beware to allow ssh rule before running this !

 task t => sub {
   Rex::UFW::enable();
 };

=item disable

  Disable UFW

  task t => sub {
    Rex::UFW::disable();
  };

=item allow

 Allow defined application rules (see /etc/ufw/application.d/)

 task t => sub {
   Rex::UFW::allow({
     application => 'OpenSSH'
   });
 };

=item forbid

 Forbid defined application rules

 task t => sub {
   Rex::UFW::forbid({
     application => 'OpenSSH'
   });
 };

=item application

 Add new application's rules set and allow it

 Rex::UFW::application({
   application => 'ngircd',
   title => 'ngircd daemon'
   description => 'ngircd daemon',
   ports => [ qw(6667/tcp) ]
 });

=back

=head1 Rex/Box

 rexify --use Rex::UFW

=cut

1;
