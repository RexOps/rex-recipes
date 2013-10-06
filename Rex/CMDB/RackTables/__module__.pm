#
# (c) Jorisd <http://github.com/jorisd>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   

package Rex::CMDB::RackTables;

use strict;
use warnings;

use Rex::Commands -no => [qw/get/];
use Rex::Logger;

use RackMan;
use RackMan::Config;

use Data::Dumper;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self
}

sub get {
   my ($self, $item, $server) = @_;

   my $env = environment;
   
   my $file = $self->{configuration_file};

   if(-f "$file") {
      my $config  = RackMan::Config->new(-file => $file);
      my $rackman = RackMan->new({ config => $config});
      my $rackobj = $rackman->device($server);

      return $rackobj->ports->[0]->{l2address_text} if($item eq 'mac');
   }

   return undef;
}

1;

=pod

=head1 NAME

Rex::CMDB::RackTables - A CMDB module to query RackTables

=head1 DESCRIPTION

This is a small CMDB module to query RackTables. Currently it supports I<mac> items. Also it doesn't return all items is no I<key> is given.

=head1 USAGE

 use Rex::CMDB::RackTables;
 
 set cmdb => {
     type => "RackTables",
     configuration_file => "./racktables.ini",
 };
 
 task yourtask => sub {
    
 };


=cut
