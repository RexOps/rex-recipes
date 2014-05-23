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

Rex::LDAP::OpenLDAP::Commands - LDAP Commands

=head1 DESCRIPTION

This module exports some ldap commands.

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

 my $entry = ldap_get "cn=jfried,ou=People,dc=rexify,dc=org";

=cut


package Rex::LDAP::OpenLDAP::Commands;

use Rex -base;
use Rex::Helper::Path;
use Carp;
use Params::Validate;
use Data::Dumper;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw/ldap_entry ldap_get ldap_search
  execute_modify_ldif_file execute_add_ldif_file/;

sub ldap_entry {
  my ( $dn, %opt ) = @_;

  Rex::Logger::debug("Setting $dn to $opt{ensure}");

  # get current status
  my $data;
  eval {
    $data = ldap_get($dn);
    1;
  };

  if ( $opt{ensure} eq "absent" ) {
    if ($data) {
      execute_delete_dn( $dn, auth => $opt{auth} );
      Rex::Logger::info("$dn removed.");
    }
  }
  else {
    if ( !$data ) {

      # dn does not exist, create it
      my $values = {%opt};
      delete $values->{ensure};

      execute_add_ldif_file(
        _generate_ldif_file(
          add    => 1,
          dn     => $dn,
          values => $values,
        ),
        auth => $opt{auth},
      );

      Rex::Logger::info("$dn added.");
    }
    else {
      for my $key ( keys %opt ) {
        next if ( $key eq "ensure" || $key eq "auth" );

        if ( $data
          && exists $data->{$key}
          && $data->{$key} ne $opt{$key} )
        {

          if ( ref $data->{$key} eq 'ARRAY'
            && (
              join( ',', @{ $opt{$key} } ) eq join( ',', @{ $data->{$key} } ) )
            )
          {
            next;
          }

          # modify entry
          execute_modify_ldif_file(
            _generate_ldif_file(
              dn      => $dn,
              replace => $key,
              value   => $opt{$key},
            ),
            auth => $opt{auth},
          );

          my $new_data = ldap_get($dn);

          if ( $new_data->{$key} ne $data->{$key} ) {
            Rex::Logger::info(
              "$dn / $key updated. New value "
                . (
                ref $new_data->{$key} eq 'ARRAY'
                ? join( ', ', @{ $new_data->{$key} } )
                : $new_data->{$key}
                )
            );
          }
        }
        elsif ( $data && !exists $data->{$key} ) {

          # modify entry
          execute_modify_ldif_file(
            _generate_ldif_file(
              dn      => $dn,
              replace => $key,
              value   => $opt{$key},
            ),
            auth => $opt{auth},
          );

          my $new_data = ldap_get($dn);

          # need to add the key
          Rex::Logger::info(
            "$dn / $key added. New value "
              . (
              ref $new_data->{$key} eq 'ARRAY'
              ? join( ', ', @{ $new_data->{$key} } )
              : $new_data->{$key}
              )
          );

        }
      }
    }
  }
}

sub _generate_ldif_file {
  my %opt = validate @_,
    {
    dn         => 0,
    add        => 0,
    changetype => { default => 'modify' },
    replace    => { default => 0 },
    value      => 0,
    values     => { default => {} },
    };

  my $content;

  if ( exists $opt{values}->{auth} && $opt{values}->{auth} eq 'EXTERNAL' ) {
    delete $opt{values}->{auth};
  }

  if ( $opt{changetype} eq 'modify' && $opt{replace} ) {
    $content = template '@ldap_modify_replace.ldif', %opt;
  }

  elsif ( $opt{add} ) {
    $content = template '@ldap_add_dn.ldif',
      dn     => $opt{dn},
      values => $opt{values};
  }

  if ( !$content ) {
    confess "Got no template content for ldif file.";
  }

  return $content;
}

sub execute_modify_ldif_file {
  my ( $content, %opt ) = @_;
  my $tmp_file = get_tmp_file;

  file $tmp_file, content => $content;

  if ( exists $opt{auth} && $opt{auth} && $opt{auth} eq 'EXTERNAL' ) {
    run "ldapmodify -Y EXTERNAL -H ldapi:/// -f $tmp_file";
  }
  else {
    run "ldapmodify -H ldap://localhost -D "
      . "'$Rex::LDAP::OpenLDAP::ldap_authentication->{bind_dn}' "
      . "-w '$Rex::LDAP::OpenLDAP::ldap_authentication->{password}' "
      . "-f $tmp_file";
  }

  if ( $? != 0 ) {
    confess "Error running ldapmodify.";
  }

  unlink $tmp_file;
}

sub execute_add_ldif_file {
  my ( $content, %opt ) = @_;
  my $tmp_file = get_tmp_file;

  file $tmp_file, content => $content;

  if ( exists $opt{auth} && $opt{auth} && $opt{auth} eq 'EXTERNAL' ) {
    run "ldapadd -Y EXTERNAL -H ldapi:/// -f $tmp_file";
  }
  else {
    run "ldapadd -H ldap://localhost -D "
      . "'$Rex::LDAP::OpenLDAP::ldap_authentication->{bind_dn}' "
      . "-w '$Rex::LDAP::OpenLDAP::ldap_authentication->{password}' "
      . "-f $tmp_file";
  }

  if ( $? != 0 ) {
    die "Error running ldapadd.";
  }

  unlink $tmp_file;
}

sub execute_delete_dn {
  my ( $dn, %opt ) = @_;

  if ( exists $opt{auth} && $opt{auth} && $opt{auth} eq 'EXTERNAL' ) {
    run "ldapdelete -Y EXTERNAL -H ldapi:/// $dn";
  }
  else {
    run "ldapdelete -H ldap://localhost -D "
      . "'$Rex::LDAP::OpenLDAP::ldap_authentication->{bind_dn}' "
      . "-w '$Rex::LDAP::OpenLDAP::ldap_authentication->{password}' "
      . $dn;
  }
}

sub ldap_search {
  my ( $filter, %option ) = @_;

  my $base_dn = $Rex::LDAP::OpenLDAP::ldap_authentication->{base_dn};
  if ( exists $option{dn} ) {
    $base_dn = $option{dn};
  }

  my @lines;

  if ( exists $option{auth} && $option{auth} eq 'EXTERNAL' ) {
    @lines =
        run "ldapsearch -Y EXTERNAL -H ldapi:/// -b "
      . "'$base_dn' "
      . "'$filter' 2>/dev/null";
  }
  else {
    @lines =
        run "ldapsearch -H ldap://localhost -b "
      . "'$base_dn' -D '$Rex::LDAP::OpenLDAP::ldap_authentication->{bind_dn}' "
      . " -w '$Rex::LDAP::OpenLDAP::ldap_authentication->{password}' "
      . "'$filter' 2>/dev/null";
  }

  if ( $? != 0 ) {
    if ( $? == 32 ) {
      confess "No such object.";
    }
    else {
      confess "Unknown error";
    }
  }

  return _parse_ldap_search(@lines);
}

sub ldap_get {
  my ($dn) = @_;

  my @lines =
    run "ldapsearch -Y EXTERNAL -H ldapi:/// -b '$dn' -s base 2>/dev/null";

  if ( $? != 0 ) {
    if ( $? == 32 ) {
      confess "No such object.";
    }
    else {
      confess "Unknown error";
    }
  }

  my @ret = _parse_ldap_search(@lines);
  return $ret[0];
}

sub _parse_ldap_search {
  my @lines = @_;

  my @ret;

  my $last_key;
  my $idx      = 0;
  my $found_dn = 0;
  for my $line (@lines) {
    next if ( $line =~ m/^#/ );
    if ( $line =~ m/^$/ && $found_dn ) { $idx++; next; }
    next if ( $line =~ m/^$/ );
    next if ( $line =~ m/^\s*$/ );

    if ( $line =~ m/^\s/ ) {
      $ret[$idx]->{$last_key} .= $line;
      next;
    }

    my ( $key, $val ) = split /:/, $line, 2;
    $val =~ s/^\s//;

    $found_dn = 1 if ( $key eq 'dn' );

    if ( exists $ret[$idx]->{$key} && !ref $ret[$idx]->{$key} ) {
      $ret[$idx]->{$key} = [ $ret[$idx]->{$key}, $val ];
    }
    elsif ( exists $ret[$idx]->{$key} && ref $ret[$idx]->{$key} eq 'ARRAY' ) {
      push @{ $ret[$idx]->{$key} }, $val;
    }
    else {
      $ret[$idx]->{$key} = $val;
    }

    $last_key = $key;
  }

  return grep { !exists $_->{search} && !exists $_->{result} } @ret;
}

1;

__DATA__

@ldap_modify_replace.ldif
dn: <%= $dn %>
changetype: modify
replace: <%= $replace %>
#<% if( ref $value eq 'ARRAY' ) { %>
#<% for my $v ( @{$value} ) { %>
<%= $replace %>: <%= $v %>
#<% } %>
#<% } else { %>
<%= $replace %>: <%= $value %>
#<% } %>
@end

@ldap_add_dn.ldif
dn: <%= $dn %>
#<% for my $key (keys %{ $values }) { %>
#<% if (ref $values->{$key} eq "ARRAY") { %>
#<% for my $val (@{ $values->{$key} }) { %>
<%= $key %>: <%= $val %>
#<% } %>
#<% } else { %>
<%= $key %>: <%= $values->{$key} %>
#<% } %>
#<% } %>
@end
