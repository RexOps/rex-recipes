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

=head1 NAME

Rex::LDAP::OpenLDAP - Install and manage OpenLDAP

=head1 DESCRIPTION

With this module you can install and manage your OpenLDAP server.

=head1 SYNOPSIS

 use Rex::LDAP::OpenLDAP;
 use Rex::LDAP::OpenLDAP::Commands;

 set openldap => {
   bind_dn  => 'cn=admin,dc=rexify,dc=org',
   password => 'test',
   base_dn  => 'dc=rexify,dc=org',
 };

 ldap_entry "ou=Services,dc=rexify,dc=org",
    ensure      => 'present',
    objectClass => [ 'top', 'organizationalUnit' ],
    ou          => 'Services';

 my @entries = ldap_search "(objectClass=posixAccount)";

=cut

package Rex::LDAP::OpenLDAP;

use strict;
use warnings;

use Rex -base;
use Rex::Test;
use Rex::Commands::Iptables;
use Rex::Ext::ParamLookup;
use Carp;

use Rex::LDAP::OpenLDAP::Commands;

#### some defaults

our %package_name = ( centos => [ 'openldap-servers', 'openldap-clients' ], );
our %client_package_name = (
  centos => [
    'openldap-clients', 'openssh-ldap', 'sssd', 'sssd-client',
    'perl-LDAP',        'perl-YAML'
  ]
);

our %service_name      = ( centos => 'slapd', );
our %service_name_sssd = ( centos => 'sssd', );

=head1 TASKS

=over 4

=item setup

This task installs openldap on your system.

Parameters:

=over 8

=item package_name

Default: openldap-servers

=item package_version

Default: latest

=item service_name

Default: openldap

=item ldap_admin_password

Default: not set

=item ldap_base_dn

The root dn that should be configured.

Default: dc=example,dc=com

=item ldap_base_dn_admin_password

The password for the admin account for the root dn.

Default: not set

=item ldap_configure_tls

Boolean value, whether to configure tls or not.

Default: FALSE

=item ldap_cacert_file

The source of the cacert file.

Default: files/openldap/certs/cacert.pem

=item slapd_key_file

The tls key file.

Default: files/openldap/certs/slapd.key

=item slapd_cert_file

The tls cert file.

Default: files/openldap/certs/slapd.crt

=back

=cut

our $ldap_authentication = {};

desc "Setup OpenLDAP Server and initialize root dn.";
task setup => make {

  # store lower case operating system name
  my $os = lc operating_system;

  # get package and service name for the current OS
  my $package_name    = param_lookup "package_name",    $package_name{$os};
  my $package_version = param_lookup "package_version", "latest";
  my $service_name    = param_lookup "service_name",    $service_name{$os};

  # some ldap options
  my $ldap_admin_password = param_lookup "ldap_admin_password", FALSE;
  my $default_base_dn = param_lookup "ldap_base_dn", "dc=example,dc=com";
  my $base_dn_admin_password = param_lookup "ldap_base_dn_admin_password",
    FALSE;

  # options for tls
  my $ldap_configure_tls = param_lookup "ldap_configure_tls", FALSE;
  my $cacert_file = param_lookup "ldap_cacert_file",
    "files/openldap/certs/cacert.pem";
  my $slapd_key_file = param_lookup "slapd_key_file",
    "files/openldap/certs/slapd.key";
  my $slapd_cert_file = param_lookup "slapd_cert_file",
    "files/openldap/certs/slapd.crt";

  # ensure that the package is installed
  pkg $package_name, ensure => $package_version;

  # make sure /var/lib/ldap is owned by ldap user (fix a bug in rhel package)
  file "/var/lib/ldap",
    ensure => "directory",
    owner  => "ldap";

  # ensure that the service is running
  service $service_name, ensure => "running";

  # open firewall port
  open_port [ 389, 636 ];
  service iptables => 'save';

  if ($ldap_admin_password) {

    # set root password, if defined
    ldap_entry 'olcDatabase={0}config,cn=config',
      ensure    => 'present',
      olcRootPW => $ldap_admin_password,
      auth      => 'EXTERNAL';
  }

  if ($default_base_dn) {

    # create all the configuration for the default base_dn

    $ldap_authentication->{bind_dn} = "cn=admin,$default_base_dn";

    file "/var/lib/ldap/DB_CONFIG",
      source => "files/DB_CONFIG",
      owner  => "ldap",
      mode   => 644;

    ldap_entry 'olcDatabase={2}bdb,cn=config',
      olcSuffix => $default_base_dn,
      olcRootDN => "cn=admin,$default_base_dn",
      ensure    => 'present',
      auth      => 'EXTERNAL';

    if ($base_dn_admin_password) {
      $ldap_authentication->{password} = $base_dn_admin_password;
      ldap_entry 'olcDatabase={2}bdb,cn=config',
        olcRootPW => $base_dn_admin_password,
        ensure    => 'present',
        auth      => 'EXTERNAL';
    }

    # ensure root dn is present
    $ldap_authentication->{base_dn} = $default_base_dn;
    my ($dc) = ( $default_base_dn =~ m/dc=([^,]+),/ );
    ldap_entry $default_base_dn,
      ensure      => 'present',
      dc          => $dc,
      objectClass => [ 'top', 'dcObject', 'organization' ],
      o           => $dc;
  }

  if ($ldap_configure_tls) {

    # configure tls and ssl
    sed qr/SLAPD_LDAPS=no/, 'SLAPD_LDAPS=yes', '/etc/sysconfig/ldap';

    file "/etc/openldap/cacerts",
      ensure => 'directory',
      owner  => 'ldap',
      group  => 'root',
      mode   => 750;

    file "/etc/openldap/cacerts/cacert.pem",
      ensure => 'present',
      source => $cacert_file,
      owner  => 'ldap',
      group  => 'root',
      mode   => 640;

    # create symlink to magic c_hash file
    my @out = run "/etc/pki/tls/misc/c_hash /etc/openldap/cacerts/cacert.pem";
    my ($key) = ( $out[0] =~ m/^([^\s]+)/ );
    ln "/etc/openldap/cacerts/cacert.pem", "/etc/openldap/cacerts/$key";

    file "/etc/openldap/certs/slapd.key",
      ensure => 'present',
      source => $slapd_key_file,
      owner  => 'ldap',
      group  => 'root',
      mode   => 640;

    file "/etc/openldap/certs/slapd.crt",
      ensure => 'present',
      source => $slapd_cert_file,
      owner  => 'ldap',
      group  => 'root',
      mode   => 640;

    ldap_entry 'cn=config',
      ensure                   => 'present',
      auth                     => 'EXTERNAL',
      olcTLSCACertificateFile  => "/etc/openldap/cacerts/$key",
      olcTLSCertificateFile    => '/etc/openldap/certs/slapd.crt',
      olcTLSCipherSuite        => 'HIGH:MEDIUM:+TLSv1:!SSLv2:+SSLv3',
      olcTLSCertificateKeyFile => '/etc/openldap/certs/slapd.key';

    service $service_name => 'restart';
  }
};

=back

=cut

Rex::Config->register_set_handler(
  "openldap",
  sub {
    $ldap_authentication = $_[0];
  }
);

1;
