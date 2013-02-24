#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::DNS::Bind;

use strict;
use warnings;

use Rex -base;

use Net::DNS;
use Data::Dumper;

sub _dns;

my $OPTION = {};

Rex::Config->register_set_handler(dns => sub {
   $OPTION = shift;
});


task list_entries => sub {
   my ($data) = @_;

   my $domain = $data->{domain};

   my @ret = ();

   for my $rr (_dns->axfr($domain)) {
      if($rr->type eq "A") {
         push(@ret, {
            data => $rr->address,
            ttl  => $rr->ttl,
            type => $rr->type,
            name => $rr->name,
            class => $rr->class,
         });
      }
      elsif($rr->type eq "TXT") {
         push(@ret, {
            data => $rr->rdata,
            ttl  => $rr->ttl,
            type => $rr->type,
            name => $rr->name,
            class => $rr->class,
         });
      }
      elsif($rr->type eq "CNAME") {
         push(@ret, {
            data => $rr->cname,
            ttl  => $rr->ttl,
            type => $rr->type,
            name => $rr->name,
            class => $rr->class,
         });
      }
      elsif($rr->type eq "MX") {
         push(@ret, {
            data => $rr->exchange,
            ttl  => $rr->ttl,
            type => $rr->type,
            name => $rr->name,
            class => $rr->class,
         });
      }
      elsif($rr->type eq "NS") {
         push(@ret, {
            data => $rr->nsdname,
            ttl  => $rr->ttl,
            name => $rr->name,
            type => $rr->type,
            class => $rr->class,
         });
      }
      else {
         Rex::Logger::debug("Unknown Data: " . Dumper($rr));
      }
   }

   return @ret;
};

task add_record => sub {
   my ($data) = @_;

   my $domain = $data->{domain};
   my $host   = $data->{host};

   my $update = Net::DNS::Update->new($domain);

   my $ttl  = $data->{ttl} ||= "86400";
   my $dns_data = $data->{data};

   my $record_type = "A";

   if(exists $data->{type}) {
      $record_type = $data->{type};
   }

   # don't add it, if there is already an A record
   $update->push(prerequisite => nxrrset("$host.$domain. $record_type"));

   $update->push(update => rr_add("$host.$domain.  $ttl  $record_type  $dns_data"));

   $update->sign_tsig($OPTION->{key_name}, $OPTION->{key});

   my $res = _dns;
   my $reply = $res->send($update);

   if($reply) {
      my $rcode = $reply->header->rcode;

      if($rcode eq "NOERROR") {
         Rex::Logger::debug("DNS record added.");
         return TRUE;
      }
      else {
         Rex::Logger::debug("Failure adding DNS record.");
         Rex::Logger::debug(Dumper($reply));

         die($rcode);
      }
   }
   else {
      Rex::Logger::debug("Failure adding DNS record: " . $res->errorstring);
      die($res->errorstring);
   }
};

task delete_record => sub {
   my ($data) = @_;

   my $domain = $data->{domain};
   my $host   = $data->{host};
   my $type   = $data->{type} || "A";

   my $update = Net::DNS::Update->new($domain);

   $update->push(prerequisite => yxrrset("$host.$domain $type"));
   $update->push(update => rr_del("$host.$domain $type"));

   $update->sign_tsig($OPTION->{key_name}, $OPTION->{key});

   my $res = _dns;
   my $reply = $res->send($update);

   if($reply) {
      my $rcode = $reply->header->rcode;

      if($rcode eq "NOERROR") {
         Rex::Logger::debug("DNS record removed.");
         return TRUE;
      }
      else {
         Rex::Logger::debug("Error removing DNS record: $rcode");
         die($rcode);
      }
   }
   else {
      Rex::Logger::debug("Error removing DNS record: " . $res->errorstring);
      die($res->errorstring);
   }
};

sub _dns {

   my $res = Net::DNS::Resolver->new;
   $res->nameservers($OPTION->{server} || "127.0.0.1");

   return $res;
}

=pod

=head1 NAME

Rex::DNS::Bind - Manage BIND from Rex.

=head1 SYNOPSIS

 set dns => {
      server => "127.0.0.1",
      key_name => "mysuperkey",
      key => "/foobar==",
 };
  
 task sometask => sub {
    Rex::DNS::Bind::add_record({
      domain => "rexify.org",
      host   => "foobar01",
      data   => "127.0.0.4",
    });
        
    Rex::DNS::Bind::delete_record({
      domain => "rexify.org",
      host   => "foobar01",
      type   => "A",
    });
        
    my @entries = Rex::DNS::Bind::list_entries(domain => "rexify.org");
    print Dumper(\@entries);
 };

=head1 SETUP

To use this module you have to setup your BIND server to accept update requests and to allow zone transfers to the server where you execute rex on. You can use I<ddns-confgen> to generate a key.


=head2 Allow zone transfer

 acl trusted-servers {
   192.168.1.3;
   127.0.0.1;
 };

=head2 Configure BIND to allow update requests

 controls {
   inet 127.0.0.1 port 953 allow { any; }
   keys { "rex"; };
 };
    
 key "rex" {
   algorithm hmac-md5;
   secret "the-secret-string";
 };
    
 zone "your-zone.com" IN {
   type master;
   file "your-zone.com.zone";
   allow-transfer { trusted-servers; };
   update-policy {
      grant rex zonesub ANY;
   };
 };

=head1 TASKS

=over 4

=item add_record($data)

With this task you can add new entries to your DNS server. You have to define the following options:

=over 4

=item domain

This is the domain where you want to add a new entry.

=item host

This is the hostname which you want to add.

=item data

This is the data you want to add. For example the IP address.

=item type

The type of DNS record you want to add. Defaults to "A".

=back

 Rex::DNS::Bind::add_record({
    domain => "foo.bar",
    host   => "myhost",
    data   => "127.0.3.1",
    type   => "A",
 });


=item delete_record($data)

With this task you can remove entries from you DNS server. You have to define the following options:

=over 4

=item domain

This is the domain from which you want to remove the entry.

=item host

The host which you want to remove.

=item type

The type which you want to remove. Defaults to "A".

=back

 Rex::DNS::Bind::delete_record({
    domain => "foo.bar",
    host   => "myhost",
    type   => "A",
 });

=item list_entries($data)

Use this task to list all entries of a Domain. You have to define the domain.

 my @entries = Rex::DNS::Bind::list_entries({domain => "foo.bar"});

=back

=cut

1;
