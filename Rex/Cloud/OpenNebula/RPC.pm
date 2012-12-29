#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Cloud::OpenNebula::RPC;

use strict;
use warnings;

use XML::Simple;
use RPC::XML;
use RPC::XML::Client;
use Rex::Logger;

use Data::Dumper;

use Rex::Cloud::OpenNebula::RPC::Host;
use Rex::Cloud::OpenNebula::RPC::Cluster;
use Rex::Cloud::OpenNebula::RPC::VM;
use Rex::Cloud::OpenNebula::RPC::Template;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub get_clusters {
   my ($self) = @_;

   my @ret = ();

   my $data = $self->_rpc("one.clusterpool.info");

   for my $cluster (@{ $data->{CLUSTER} }) {
      push(@ret, Rex::Cloud::OpenNebula::RPC::Cluster->new(rpc => $self, data => $cluster));
   }

   return @ret;
}

sub get_hosts {
   my ($self) = @_;

   my @ret = ();

   my $data = $self->_rpc("one.hostpool.info");

   for my $host (@{ $data->{HOST} }) {
      push(@ret, Rex::Cloud::OpenNebula::RPC::Host->new(rpc => $self, data => $host));
   }

   return @ret;
}

sub get_host {
   my ($self, $id) = @_;

   if(! defined $id) {
      die("You have to define the ID => Usage: \$obj->get_host(\$host_id)");
   }

   my $data = $self->_rpc("one.host.info", [ int => $id ]);
   return Rex::Cloud::OpenNebula::RPC::Host->new(rpc => $self, data => $data, extended_data => $data);
}

sub get_vms {
   my ($self) = @_;

   my $data = $self->_rpc("one.vmpool.info", 
                           [ int => -2 ], # always get all resources
                           [ int => -1 ], # range from (begin)
                           [ int => -1 ], # range to (end)
                           [ int => -2 ], # all states
                         ); 

   my @ret = ();

   for my $vm (@{ $data->{VM} }) {
      push(@ret, Rex::Cloud::OpenNebula::RPC::VM->new(rpc => $self, data => $vm));
   }

   return @ret;
}

sub get_vm {
   my ($self, $id) = @_;

   if(! defined $id) {
      die("You have to define the ID => Usage: \$obj->get_vm(\$vm_id)");
   }

   my $data = $self->_rpc("one.vm.info", [ int => $id ]);
   return Rex::Cloud::OpenNebula::RPC::VM->new(rpc => $self, data => $data, extended_data => $data);
}

sub get_templates {
   my ($self) = @_;

   my $data = $self->_rpc("one.templatepool.info",
                           [ int => -2 ], # all templates
                           [ int => -1 ], # range start
                           [ int => -1 ], # range end
                         );

   my @ret = ();

   for my $tpl (@{ $data->{VMTEMPLATE} } ) {
      push(@ret, Rex::Cloud::OpenNebula::RPC::Template->new(rpc => $self, data => $tpl));
   }

   return @ret;
}

sub create_vm {
   my ($self, %option) = @_;

   my ($template) = grep { $_->name eq $option{template} } $self->get_templates;   

   my $hash_ref = $template->get_template_ref;
   $hash_ref->{TEMPLATE}->[0]->{NAME}->[0] = $option{name};

   my $s = XMLout($hash_ref, RootName => undef, NoIndent => 1 );

   my $res = $self->_rpc("one.vm.allocate", [ string => $s ]);

   return $self->get_vm($res);
}

sub _rpc {
   my ($self, $meth, @params) = @_;                                                                                

   my @params_o = (RPC::XML::string->new($self->{user} . ":" . $self->{password}));
   for my $p (@params) {
      my $klass = "RPC::XML::" . $p->[0];
      push(@params_o, $klass->new($p->[1]));
   }   

   my $req = RPC::XML::request->new($meth, @params_o);
   my $cli = RPC::XML::Client->new("http://172.16.120.131:2633/RPC2");
   my $resp = $cli->send_request($req);
   
   my $ret = $resp->value;

   Rex::Logger::debug($ret->[1]);

   if($ret->[0] == 1) {
      if($ret->[1] =~ m/^\d+$/) {
         return $ret->[1];
      }
      else {
         return XMLin($ret->[1], ForceArray => 1);
      }
   }   

   else {
      Rex::Logger::debug(Dumper($resp));
      die("error sending request.");
   }   

}

1;

