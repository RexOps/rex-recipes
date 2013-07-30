#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Ext::AutoIterate;

use Rex::Commands;
use Devel::Caller qw(caller_cv);
use Filter::Simple;

$Rex::Commands::REGISTER_SUB_HASH_PARAMTER = 0;

FILTER {
   s/iterate (\$[a-zA-Z0-9_]+)/return if(iterate($1));/gms;
};

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
use Data::Dumper;
@EXPORT = qw(iterate);

sub iterate {
   return if ref $_[0] ne "ARRAY";
   my $caller = caller_cv(1);

   for my $x (@{ $_[0] }) {
      $caller->($x);
   }   

   1;  
}

1;

=pod

=head1 NAME

Rex::Ext::AuoIterate - Automatically iterate over task parameters.

With this extension it is easy to write tasks/functions that can interact with arrayRef parameters without changing your code.

=head1 LIMITATIONS

With this module it is not possible to call tasks without a hash reference or a array reference.

=head1 SYNOPSIS

 # Rexfile
 use Rex::Ext::AutoIterate;
   
 task "prepare", sub {
    my $param = shift;
    iterate $param;
      
    run "somecommand $param";
 };

=cut

1;

