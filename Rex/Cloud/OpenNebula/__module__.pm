#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Cloud::OpenNebula;

use strict;
use warnings;

use Rex -base;
use Rex::Cloud::OpenNebula::RPC;

my %ONE_CONF = ();

sub _rpc;

# set one => url      => "http://172.16.120.131:2633/RPC2";
# set one => user     => "oneadmin";
# set one => password => "opennebula";
#### or
# set one => url      => "http://172.16.120.131:2633/RPC2",
#            user     => "oneadmin",
#            password => "opennebula";

Rex::Config->register_set_handler("one" => sub {
   my (%param) = @_;

   for my $key (keys %param) {
      $ONE_CONF{$key} = $param{$key};
   }
});


# will return a list of all available opennebula clusters
sub get_clusters {
   _rpc->get_clusters;
};

sub get_hosts {
   _rpc->get_hosts;
}

sub get_host {
   _rpc->get_host(@_);
}

sub get_vms {
   _rpc->get_vms;
}

sub get_vm {
   _rpc->get_vm(@_);
}

sub get_templates {
   _rpc->get_templates;
}

sub create_vm {
   _rpc->create_vm(@_);
}

sub shutdown_vm {
   my ($vm_id) = @_;
   
   my $vm;
   if($vm_id =~ m/^\d+$/) {
      $vm = get_vm($vm_id);
   }
   else {
      ($vm) = grep { $_->name eq $vm_id } get_vms();
   }
   
   $vm->shutdown;
}

sub _rpc {
   return Rex::Cloud::OpenNebula::RPC->new(url => $ONE_CONF{url}, user => $ONE_CONF{user}, password => $ONE_CONF{password});
}

1;

=pod

 include qw/Rex::Cloud::OpenNebula/;                                                                               
 
 set one => url      => "http://172.16.120.131:2633/RPC2",
            user     => "oneadmin",
            password => "opennebula";
 
 task test => sub {
 
    print Dumper Rex::Cloud::OpenNebula::get_clusters();
    print Dumper Rex::Cloud::OpenNebula::get_hosts();
    print Dumper Rex::Cloud::OpenNebula::get_vms();
    print Dumper Rex::Cloud::OpenNebula::get_templates();
 
    my @templates = Rex::Cloud::OpenNebula::get_templates();
    for my $tpl (@templates) {
       say "id   > " . $tpl->id;
       say "name > " . $tpl->name;
    }
 
    print Dumper Rex::Cloud::OpenNebula::create_vm(
       name => "foo02",
       template => "template-1",
    );
 
    Rex::Cloud::OpenNebula::shutdown_vm("foo02");
 
    my @hosts = Rex::Cloud::OpenNebula::get_hosts();
    for my $host (@hosts) {
       say "id   > " . $host->id;
       say "name > " . $host->name;
    }
 
    my $host = Rex::Cloud::OpenNebula::get_host(0);
    say "id   > " . $host->id;
    say "name > " . $host->name;
 
    my @vms = Rex::Cloud::OpenNebula::get_vms();
    say "> " . $vms[0]->name;
 
    my $vm = Rex::Cloud::OpenNebula::get_vm(0);
 
    say "vm> " . $vm->name;
 
    my @nics = $vm->nics;
 
    for my $nic (@nics) {
       say "ip     > " . $nic->ip;
       say "mac    > " . $nic->mac;
       say "bridge > " . $nic->bridge;
    }
 
 };
 
 
