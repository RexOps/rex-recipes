#!/usr/bin/perl

use strict;
use warnings;

use YAML;
use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_SUCCESS);
use Data::Dumper;

my $config = YAML::LoadFile("/etc/ssh/pubkey.yaml");

if ( !exists $config->{base_dn} ) {
  die "No base_dn found in configuration.";
}

if ( !exists $config->{host} ) {
  $config->{host} = "ldap://localhost";
}

if ( !exists $config->{filter} ) {
  $config->{filter} = '(&(uid={{LOGIN_NAME}})(objectClass=posixAccount)))';
}

my $ldap = Net::LDAP->new( $config->{host} );

my $filter = $config->{filter};
$filter =~ s/\{\{LOGIN_NAME\}\}/$ARGV[0]/;

if ( exists $config->{tls} ) {
  my $tls = $ldap->start_tls( %{ $config->{tls} } );
  if ( $tls->code() != LDAP_SUCCESS ) {
    die "Can't start TLS.";
  }
}

if ( exists $config->{bind_dn} && exists $config->{bind_pw} ) {
  my $bind = $ldap->bind( $config->{bind_dn}, password => $config->{bind_pw} )
    or die($!);
  if ( $bind->code() != LDAP_SUCCESS ) {
    die "Can't bind with $config->{bind_dn}.";
  }
}

my $res = $ldap->search(
  base   => $config->{base_dn},
  filter => $filter,
);

if ( $res->code() != LDAP_SUCCESS ) {
  die "Search failed.";
}

my @entries = $res->entries;

if ( scalar @entries == 0 ) {
  die "No user found.";
}

print $entries[0]->get_value('sshPublicKey');

print "\n";
