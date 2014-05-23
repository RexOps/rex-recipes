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

Rex::LDAP::OpenLDAP::UserManagement::Commands - LDAP Commands for user management

=head1 DESCRIPTION

This module exports some ldap commands for user management.

=head1 SYNOPSIS

 use Rex::LDAP::OpenLDAP;
 use Rex::LDAP::OpenLDAP::UserManagement::Commands;

 set openldap => {
   bind_dn  => 'cn=admin,dc=rexify,dc=org',
   password => 'test',
   base_dn  => 'dc=rexify,dc=org',
 };

 ldap_group "ldapusers",
   ensure    => 'present',
   dn        => 'ou=Groups,dc=rexify,dc=org',
   gidNumber => 3000;

 ldap_account "jfried",
   ensure        => 'present',
   dn            => 'ou=People,dc=rexify,dc=org',
   givenName     => 'Jan',
   sn            => 'Gehring',
   uidNumber     => '5000',
   gidNumber     => 3000,
   homeDirectory => '/home/jfried',
   loginShell    => '/bin/bash',
   mail          => 'jan.gehring@gmail.com',
   userPassword  => '{CRYPT}vPYgtKD.j9iL2',
   sshPublicKey  =>  'ssh-rsa AAAAB3Nz...',
   groups        => ['cn=ldapusers,ou=Groups,dc=rexify,dc=org'];

=cut


package Rex::LDAP::OpenLDAP::UserManagement::Commands;

use Rex -base;
use Rex::Helper::Path;
use Rex::Ext::ParamLookup;

use Carp;
use Params::Validate;
use Data::Dumper;
use List::MoreUtils 'uniq';
use Rex::LDAP::OpenLDAP::Commands;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(ldap_account ldap_group);

sub ldap_account {
  my ( $name, %option ) = @_;

  $option{ensure} ||= 'present';

  $option{uid}         = $name;
  $option{objectClass} = [qw/top inetOrgPerson posixAccount shadowAccount/];
  if ( $option{sshPublicKey} ) {
    push @{ $option{objectClass} }, 'ldapPublicKey';
  }
  my $dn = $option{dn};
  delete $option{dn};

  my $groups = $option{groups};
  delete $option{groups};

  ldap_entry "cn=$name,$dn", %option;

  if ($groups) {
    for my $group ( @{$groups} ) {
      my @new_uids;
      my $group_o = ldap_get $group;

      if ( !$group_o ) {
        die "Group $group not found.";
      }

      my $found_key = 0;
      for my $key ( keys %{$group_o} ) {
        if ( lc($key) eq 'memberuid' ) {
          if ( ref $group_o->{$key} eq 'ARRAY' ) {
            push @new_uids, @{ $group_o->{$key} }, "cn=$name,$dn";
          }
          else {
            push @new_uids, $group_o->{$key}, "cn=$name,$dn";
          }
          $found_key = 1;
        }
      }
      if ( !$found_key ) {
        push @new_uids, "cn=$name,$dn";
      }

      ldap_entry $group,
        ensure    => 'present',
        memberUid => [ uniq @new_uids ];
    }

    # search for groups to remove the user from
    my @found = ldap_search "(memberuid=cn=$name,$dn)";
    for my $f (@found) {
      my $group_name = $f->{dn};
      unless ( $group_name ~~ @{$groups} ) {
        # remove the user from this group
        my @new_users = grep { $_ ne "cn=$name,$dn" } @{ $f->{memberUid} };
        ldap_entry $group_name,
          ensure    => 'present',
          memberUid => \@new_users;
      }
    }
  }
}

sub ldap_group {
  my ( $name, %option ) = @_;

  $option{ensure} ||= 'present';

  $option{cn} = $name;
  $option{userPassword} ||= '{crypt}x';
  $option{objectClass} = [qw/top posixGroup/];
  my $dn = $option{dn};
  delete $option{dn};

  ldap_entry "cn=$name,$dn", %option;
}

1;
