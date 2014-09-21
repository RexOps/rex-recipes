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

task disable => sub {

  Rex::Logger::info("Disabling UFW");
  run "ufw disable";
};

task delete => sub {
  my ($name) = @_;

  Rex::Logger::info("Removing UFW $name rules");
  run "ufw delete allow $name";
};

task add => sub {
  my ($name, $data) = @_;


  if (ref $data eq 'HASH') {
    $data->{name} = $name;

    file "/etc/ufw/applications.d/$name",
      content => template_toolkit( "templates/etc/ufw/applications.d/application.tpl", $data ),
      owner   => "root",
      group   => "root",
      mode    => 644;
  };

  Rex::Logger::info("Adding UFW $name rules");
  run "ufw allow $name";

  Rex::Logger::info("Enabling UFW");
  run "ufw --force enable";
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
  Rex::UFW::add('OpenSSH');
 };

 task "irc_server", sub {

  # ... do stuff

  # add new ufw application
  Rex::UFW::add(
    'ngIRCd' => {
      title => 'ngircd daemon'
      description => 'ngircd daemon',
      ports => [ qw(6667/tcp) ]
      }
  );
 };

=head1 METHODS

You can use the following methods to control UFW behavior.

=over 4

=item setup

 Install ufw package

 task t => sub {
   Rex::UFW::setup();
 };

=item add

 Allow defined application rules (see /etc/ufw/application.d/)
 Auto enable UFW

 # if application description file already exists
 task t => sub {
   Rex::UFW::add('OpenSSH');
 };

 # create new file and allow new rule(s)
 task t => sub {
   Rex::UFW::add(
     'ngIRCd' => {
       title => 'ngircd daemon' # optional
       description => 'ngircd daemon', # optional
       ports => [ qw(6667/tcp) ]
      }
   );
 };

=item delete

 Delete application rules

 task t => sub {
   Rex::UFW::delete('ngIRCd');
 };

=item disable

  Disable UFW

  task t => sub {
    Rex::UFW::disable();
  };

=back

=head1 Rex/Box

 rexify --use Rex::UFW

=cut

1;
