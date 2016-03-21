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
      content   => template("files/suite.ini", threshold => $params->{threshold} || 80 ),
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

   my $output = run "sparrow check run system disk";
   my $status = $?;
   say $output;

   die "sparrow check run system disk returned bad exit code" unless  $status == 0;

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

=over 4

=item configure

Configure test suite. Use threshold to set minimum availbale disk space to allow in percentage

   rex -H 127.0.0.1:2222 -u root -p 123 Misc:Sparrow:DiskCheck:configure --threshold=80

=back

=cut

=head1 See Also

https://sparrowhub.org/info/df-check

