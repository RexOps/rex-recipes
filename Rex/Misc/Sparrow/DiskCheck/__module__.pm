package Rex::Misc::Sparrow::DiskCheck;

use Rex -base;
use Rex::Misc::ShellBlock;

task prepare => sub {

   my ( $params ) = @_;

   my $proxy_export = $params->{proxy} ? 
   "export http_proxy=$params->{proxy}; export https_proxy=$params->{proxy};" : "";

   install package => 'curl';

   my $output = run "$proxy_export curl -fkL http://cpanmin.us/ -o /bin/cpanm && chmod +x /bin/cpanm";  
   say $output;

   my $output = run "$proxy_export cpanm Sparrow";
   say $output;
  

};

task setup => sub {
   my $output = run "hostname -f";
   say $output;
};

#task setup => sub {
#   my $output = run "hostname -f";
#   say $output;
#};

1;

=pod

=head1 NAME

$::module_name - {{ SHORT DESCRIPTION }}

=head1 DESCRIPTION

{{ LONG DESCRIPTION }}

=head1 USAGE

{{ USAGE DESCRIPTION }}

 include qw/Rex::Misc::Sparrow::DiskCheck/;

 task yourtask => sub {
    Rex::Misc::Sparrow::DiskCheck::example();
 };

=head1 TASKS

=over 4

=item example

This is an example Task. This task just output's the uptime of the system.

=back

=cut
