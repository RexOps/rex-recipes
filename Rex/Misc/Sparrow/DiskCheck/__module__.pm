package Rex::Misc::Sparrow::DiskCheck;

use Rex -base;
use Rex::Misc::ShellBlock;

task prepare => sub {

   my ( $params ) = @_;

   install package => 'curl';
   
   my $output = run "curl -fkL http://cpanmin.us/ -o /bin/cpanm && chmod +x /bin/cpanm";  
   say $output;

   my $output = run "cpanm Sparrow";
   say $output;
  

};

task setup => sub {

   my ( $params ) = @_;

   my $output = run "export PATH=/usr/local/bin/PATH:\$PATH; sparrow index update && sparrow install df-check";  
   say $output;

};

#task setup => sub {
#   my $output = run "hostname -f";
#   say $output;
#};

1;

=pod

=head1 NAME

Rex::Misc::Sparrow::DiskCheck - elementary file system checks using df utility report 

=head1 DESCRIPTION

Checks available disk spaces parsing `df -h` output

=head1 USAGE

To execute check:

 include qw/Rex::Misc::Sparrow::DiskCheck/;

 task run => sub {
    Rex::Misc::Sparrow::DiskCheck::run();
 };

=head1 TASKS

=over 4

=item setup

Installs sparrow plugin

=back

=cut

=head1 See Also

https://sparrowhub.org/info/df-check

