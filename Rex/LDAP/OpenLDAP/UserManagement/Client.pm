#
# AUTHOR: jan gehring <jan.gehring@gmail.com>
# REQUIRES:
# LICENSE: Apache License 2.0
#
# Module to manage OpenLDAP
#
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::LDAP::OpenLDAP::UserManagement::Client;

use Rex -base;
use Rex::Helper::Path;
use Rex::Ext::ParamLookup;

use Carp;
use Params::Validate;
use Data::Dumper;
use List::MoreUtils 'uniq';
use Rex::LDAP::OpenLDAP::Commands;

desc "Prepare a system (pam) to authenticate against LDAP.";
task setup => sub {
  my $os           = lc operating_system;
  my $package_name = param_lookup "package_name",
    $Rex::LDAP::OpenLDAP::client_package_name{$os};

  my $ldap_base_dn       = param_lookup "ldap_base_dn";
  my $ldap_uri           = param_lookup "ldap_uri";
  my $ldap_bind_dn       = param_lookup "ldap_bind_dn";
  my $ldap_bind_password = param_lookup "ldap_bind_password";
  my $ldap_base_group_dn = param_lookup "ldap_base_group_dn";
  my $ldap_base_user_dn  = param_lookup "ldap_base_user_dn";
  my $configure_ssh_ldap = param_lookup "configure_ssh_ldap";

  pkg $package_name, ensure => 'present';

  service 'sssd', ensure => 'started';

  run "authconfig",
    command => 'authconfig --enablesssd --enablesssdauth '
    . '--enablemkhomedir --updateall',
    creates => "/etc/sssd/sssd.conf";

  file "/etc/openldap/ldap.conf",
    ensure  => 'present',
    content => template( "templates/$os/ldap.conf.tpl", ),
    owner   => 'root',
    group   => 'root',
    mode    => 644;

  file "/etc/sssd/sssd.conf",
    ensure    => 'present',
    content   => template( "templates/$os/sssd.conf.tpl", ),
    owner     => 'root',
    group     => 'root',
    mode      => 600,
    on_change => make {
    service sssd => 'restart';
    };

  if ($configure_ssh_ldap) {
    
    file '/etc/ssh/pubkey.yaml',
      ensure  => 'present',
      owner   => 'nobody',
      mode    => 600,
      content => template('templates/etc/ssh/pubkey.yaml.tpl');

    file '/usr/local/bin/get-ssh-pub-key-from-ldap',
      ensure => 'present',
      source => 'files/get-ssh-pub-key-from-ldap.pl',
      owner  => 'root',
      mode   => 755;

    append_if_no_such_line '/etc/ssh/sshd_config',
      line => 'AuthorizedKeysCommand /usr/local/bin/get-ssh-pub-key-from-ldap',
      regexp    => [qr/^AuthorizedKeysCommand/],
      on_change => make { service sshd => 'restart' };

    append_if_no_such_line '/etc/ssh/sshd_config',
      line      => 'AuthorizedKeysCommandRunAs nobody',
      regexp    => [qr/^AuthorizedKeysCommandRunAs/],
      on_change => make { service sshd => 'restart' };

  }

};

1;
