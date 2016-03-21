package Rex::Misc::Sparrow::DiskCheck;

use Rex -base;
use Rex::Misc::ShellBlock;

task prepare => sub {

   my ( $params ) = @_;

   install package => 'curl';
   install package => 'perl-devel';
   
   my $output = run "curl -fkL http://cpanmin.us/ -o /bin/cpanm && chmod +x /bin/cpanm";  
   say $output;

   my $output = run "cpanm Test::More Sparrow";
   say $output;
  

};

task setup => sub {

   my ( $params ) = @_;

   my $output = run "sparrow index update && sparrow plg install df-check";  

   say $output;

};

task configure => sub {

   my ( $params ) = @_;

   file "/tmp/sparrow-df-check.ini",
      content   => template("files/etc/ntp.conf", threshold => $params->{threshold} || 80 ),
   ;

   my $output = run "sparrow project create system";  
   say $output;

   my $output = run "sparrow check add system disk";  
   say $output;

   my $output = run "sparrow check set system disk df-check";  
   say $output;

   my $output = run "sparrow check load_ini system disk /tmp/sparrow-df-check.ini";  
   say $output;

   my $output = run "sparrow check show system disk";  
   say $output;


};

task run => sub {
   my $output = run "sparrow plg run df-check";
   say $output;
};

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

