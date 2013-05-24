#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Cloud::OpenNebula;

use strict;
use warnings;

use Rex -base;
use Rex::Commands::User;
use Rex::Cloud::OpenNebula::RPC;

use Rex::Cloud;

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

# Register cloud service to Rex::Cloud
Rex::Cloud->register_cloud_service(opennebula => "Rex::Cloud::OpenNebula::CloudLayer");

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

sub terminate_vm {
   my ($vm_id) = @_;
   
   my $vm;
   if($vm_id =~ m/^\d+$/) {
      $vm = get_vm($vm_id);
   }
   else {
      ($vm) = grep { $_->name eq $vm_id } get_vms();
   }
   
   $vm->stop;
}

sub _rpc {
   return Rex::Cloud::OpenNebula::RPC->new(url => $ONE_CONF{url}, user => $ONE_CONF{user}, password => $ONE_CONF{password});
}

task "repositories", sub {

   my $op = operating_system;

   # Add local repository and update package database
   repository "add" => "opennebula", {
      CentOS => {
         gpgcheck   => 0,
         url        => "http://opennebula.linux-files.org/centos/6.4/x86_64",
      },
      Ubuntu => {
         url        => "http://opennebula.linux-files.org/ubuntu/12.10/amd64",
         repository => "./",
      },
   };

   update_package_db;

};

task "setup", sub {

   repositories();

   install [qw/opennebula opennebula-server opennebula-sunstone/];

   sed qr{:host: 127\.0\.0\.1}, ":host: 0.0.0.0", "/etc/one/sunstone-server.conf";

   service opennebula => "ensure", "started";
   service "opennebula-sunstone" => "ensure", "started";

};

task "setup_node", sub {

   install [qw/opennebula-node-kvm/];
   service libvirtd => "ensure", "started";

   create_user "oneadmin",
      home => "/var/lib/one";

   mkdir "/var/lib/one/.ssh",
      owner => "oneadmin",
      mode  => 700;

   my ($host) = ($ONE_CONF{url} =~ m/http:\/\/([^:]+):/);
   my $pubkey = run_task "get_ssh_key", on => $host;

   file "/var/lib/one/.ssh/authorized_keys",
      owner  => "oneadmin",
      mode   => 600,
      content => $pubkey;

   add_node({
      host => connection->server->{name},
   });

};

task "get_ssh_key", sub {
   return cat "/var/lib/one/.ssh/id_dsa.pub";
};

task "add_node", sub {
   my $param = shift;

   LOCAL {
      my $c = Rex::Cloud::OpenNebula::RPC->new(url  => $ONE_CONF{url},
                                               user => $ONE_CONF{user},
                                               password => $ONE_CONF{password});

      $c->create_host(
         name => $param->{host},
         im_mad => "kvm",
         vmm_mad => "kvm",
         vnm_mad => "dummy",
      );
   };

};


1;

=pod

=head1 NAME

Rex::Cloud::OpenNebula - Module to manage OpenNebula.

=head1 DESCRIPTION

This module offers functions to manage OpenNebula Cloud via its XMLRPC interface. There is also a Rex Cloud Layer to use this Module with the Rex Cloud functions.

=head1 SYNOPSIS

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
 
=cut

