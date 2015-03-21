#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Commands::Firewall::Provider::iptables;

use strict;
use warnings;

use Rex::Commands::Iptables;
use Data::Dumper;
use base qw(Rex::Commands::Firewall::Provider::base);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  return $self;
}

sub present {
  my ( $self, $rule_config ) = @_;

  my @iptables_rule = ();

  $rule_config->{dport} ||= $rule_config->{port};

  push( @iptables_rule, t => $rule_config->{table} )
    if ( defined $rule_config->{table} );
  push( @iptables_rule, A => uc( $rule_config->{chain} ) )
    if ( defined $rule_config->{chain} );
  push( @iptables_rule, p => $rule_config->{proto} )
    if ( defined $rule_config->{proto} );
  push( @iptables_rule, m => $rule_config->{proto} )
    if ( defined $rule_config->{proto} );
  push( @iptables_rule, s => $rule_config->{source} )
    if ( defined $rule_config->{source} );
  push( @iptables_rule, d => $rule_config->{destination} )
    if ( defined $rule_config->{destination} );
  push( @iptables_rule, sport => $rule_config->{sport} )
    if ( defined $rule_config->{sport} );
  push( @iptables_rule, dport => $rule_config->{dport} )
    if ( defined $rule_config->{dport} );
  push( @iptables_rule, "tcp-flags" => $rule_config->{tcp_flags} )
    if ( defined $rule_config->{tcp_flags} );
  push( @iptables_rule, "i" => $rule_config->{iniface} )
    if ( defined $rule_config->{iniface} );
  push( @iptables_rule, "o" => $rule_config->{outiface} )
    if ( defined $rule_config->{outiface} );
  push( @iptables_rule, "reject-with" => $rule_config->{reject_with} )
    if ( defined $rule_config->{reject_with} );
  push( @iptables_rule, "log-level" => $rule_config->{log_level} )
    if ( defined $rule_config->{log_level} );
  push( @iptables_rule, "log-prefix" => $rule_config->{log_prefix} )
    if ( defined $rule_config->{log_prefix} );
  push( @iptables_rule, "state" => $rule_config->{state} )
    if ( defined $rule_config->{state} );
  push( @iptables_rule, j => uc( $rule_config->{action} ) )
    if ( defined $rule_config->{action} );

  if ( !Rex::Commands::Iptables::_rule_exists(@iptables_rule) ) {
    iptables(@iptables_rule);
    return 1;
  }

  return 0;
}

sub absent {
  my ( $self, $rule_config ) = @_;

  my @iptables_rule = ();

  $rule_config->{dport} ||= $rule_config->{port};

  push( @iptables_rule, t => $rule_config->{table} )
    if ( defined $rule_config->{table} );
  push( @iptables_rule, D => uc( $rule_config->{chain} ) )
    if ( defined $rule_config->{chain} );
  push( @iptables_rule, p => $rule_config->{proto} )
    if ( defined $rule_config->{proto} );
  push( @iptables_rule, m => $rule_config->{proto} )
    if ( defined $rule_config->{proto} );
  push( @iptables_rule, s => $rule_config->{source} )
    if ( defined $rule_config->{source} );
  push( @iptables_rule, d => $rule_config->{destination} )
    if ( defined $rule_config->{destination} );
  push( @iptables_rule, sport => $rule_config->{sport} )
    if ( defined $rule_config->{sport} );
  push( @iptables_rule, dport => $rule_config->{dport} )
    if ( defined $rule_config->{dport} );
  push( @iptables_rule, "tcp-flags" => $rule_config->{tcp_flags} )
    if ( defined $rule_config->{tcp_flags} );
  push( @iptables_rule, "i" => $rule_config->{iniface} )
    if ( defined $rule_config->{iniface} );
  push( @iptables_rule, "o" => $rule_config->{outiface} )
    if ( defined $rule_config->{outiface} );
  push( @iptables_rule, "reject-with" => $rule_config->{reject_with} )
    if ( defined $rule_config->{reject_with} );
  push( @iptables_rule, "log-level" => $rule_config->{log_level} )
    if ( defined $rule_config->{log_level} );
  push( @iptables_rule, "log-prefix" => $rule_config->{log_prefix} )
    if ( defined $rule_config->{log_prefix} );
  push( @iptables_rule, "state" => $rule_config->{state} )
    if ( defined $rule_config->{state} );
  push( @iptables_rule, j => uc( $rule_config->{action} ) )
    if ( defined $rule_config->{action} );

  my @test_rule = @iptables_rule;
  $test_rule[0] = "A";

  if ( Rex::Commands::Iptables::_rule_exists(@test_rule) ) {
    iptables(@iptables_rule);
    return 1;
  }

  return 0;
}

1;
