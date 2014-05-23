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

package Rex::LDAP::OpenLDAP::UserManagement::Server;

use Rex -base;
use Rex::Helper::Path;
use Rex::Ext::ParamLookup;

use Carp;
use Data::Dumper;
use Rex::LDAP::OpenLDAP::Commands;

desc "Add sshPublicKey schema to OpenLDAP";
task add_ssh_public_key => sub {
  my @entries = ldap_search '(objectClass=olcSchemaConfig)',
    dn   => 'cn=schema,cn=config',
    auth => 'EXTERNAL';

  my ($openssh_lpk) =
    grep { $_->{dn} =~ m/openssh-lpk,cn=schema,cn=config$/ } @entries;

  if ( !$openssh_lpk ) {
    ldap_entry 'cn=openssh-lpk,cn=schema,cn=config',
      auth        => 'EXTERNAL',
      ensure      => 'present',
      cn          => 'openssh-lpk',
      objectClass => 'olcSchemaConfig',
      olcAttributeTypes =>
      "( 1.3.6.1.4.1.24552.500.1.1.1.13 NAME 'sshPublicKey' "
      . " DESC 'MANDATORY: OpenSSH Public Key' EQUALITY "
      . " octetStringMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )",
      olcObjectClasses =>
      "( 1.3.6.1.4.1.24552.500.1.1.2.0 NAME 'ldapPublicKey' "
      . " SUP top AUXILIARY DESC 'MANDATORY: OpenSSH LPK objectclass' "
      . " MAY ( sshPublicKey \$ uid ) )";
  }

};

1;
