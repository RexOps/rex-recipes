#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Commands::Firewall - Firewall functions

=head1 DESCRIPTION

With this module it is easy to manage different firewall systems. 

=head1 SYNOPSIS

 task "configure_firewall", "server01", sub {
   firewall "some-name",
     ensure      => "present",
     proto       => "tcp",
     action      => "accept",
     source      => "192.168.178.0/24",
     destination => "192.168.1.0/24",
     sport       => 80,
     dport       => 80,
     tcp_flags   => ["FIN", "SYN", "RST"],
     chain       => "INPUT",
     table       => "nat",
     jump        => "LOG",
     iniface     => "eth0",
     outiface    => "eth1",
     reject_with => "icmp-host-prohibited",
     log_level   => "",
     log_prefix  => "FW:",
     state       => "NEW";
 };
 

=head1 EXPORTED FUNCTIONS

=over 4

=cut

package Rex::Commands::Firewall;

use strict;
use warnings;

# VERSION

require Rex::Exporter;
use Data::Dumper;
use Rex::Ext::ParamLookup;

use Rex -base;
use Rex::Resource::Common;

use Carp;

my $__provider = { default => "Rex::Commands::Firewall::Provider::iptables", };

=item firewall($name, @params)

=cut

resource "firewall", { export => TRUE }, sub {
  my $rule_name = resource_name;

  my $rule_config = {
    action      => param_lookup("action"),
    ensure      => param_lookup( "ensure", "present" ),
    proto       => param_lookup( "proto", "tcp" ),
    source      => param_lookup( "source", undef ),
    destination => param_lookup( "destination", undef ),
    port        => param_lookup( "port", undef ),
    sport       => param_lookup( "sport", undef ),
    dport       => param_lookup( "dport", undef ),
    tcp_flags   => param_lookup( "tcp_falgs", undef ),
    chain       => param_lookup( "chain", "input" ),
    table       => param_lookup( "table", "filter" ),
    iniface     => param_lookup( "iniface", undef ),
    outiface    => param_lookup( "outiface", undef ),
    reject_with => param_lookup( "reject_with", undef ),
    log_level   => param_lookup( "log_level", undef ),
    log_prefix  => param_lookup( "log_prefix", undef ),
    state       => param_lookup( "state", undef ),
  };

  my $provider =
    param_lookup( "provider", case ( lc(operating_system), $__provider ) );

  $provider->require;
  my $provider_o = $provider->new();

  my $changed = 0;
  if ( $rule_config->{ensure} eq "present" ) {
    if($provider_o->present($rule_config)) {
      emit created, "Firewall rule created.";
    }
  }
  elsif ( $rule_config->{ensure} eq "absent" ) {
    if($provider_o->absent($rule_config)) {
      emit removed, "Firewall rule removed.";
    }
  }
  else {
    die "Error: $rule_config->{ensure} not a valid option for 'ensure'.";
  }


};

1;
