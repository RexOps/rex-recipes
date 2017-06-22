package Rex::CSS::Sass;

use strict;
use warnings;

# REX dependencies
use Rex::Commands;
use Rex::Commands::Run;
use Rex::Commands::Gather;
use Rex::Commands::Fs;
use Rex::Logger;
use Rex::Lang::Perl::Cpanm;

use Data::Dumper;

our %command = (
   Debian => "/usr/local/bin/psass",
   Ubuntu => "/usr/local/bin/psass",
   CentOS => "/usr/local/bin/psass",
);

my %SASS_CONF = ();

Rex::Config->register_set_handler("sass" => sub {
   my ($name, $value) = @_;
   $SASS_CONF{$name} = $value;
});


task "setup" => sub {
   Rex::Logger::debug("Installing cpanm...");
   cpanm -install;	#Install cpan minus
	
   Rex::Logger::debug("Installing CSS::Sass");
   cpanm -install => [ 'File::Slurp', 'Encode::Locale', 'Test::Differences' ,'CSS::Sass' ];
};



desc "Parse a file, typically a .scss file";
task "parseFile" => sub {	
   my $param = shift;  
   #key is the source_file in this rex task

   my $key = $param;
   my $output_file;
   my $output_style;

   if (ref($param) eq ref {}) {   
      $key = (keys $param)[0];	  
	  $output_file = $param->{$key}->{output};
	  $output_style = $param->{$key}->{type};
   }

   my $source_file;  
   die("You need to specify a file to parse.") unless $source_file  = $key ? $key : '';

   if (!$output_file) {
      $output_file = $source_file.'.css';
   }
	
   my @output_style_values = qw(expanded nested compressed compact);
   
   if (!$output_style) {
      $output_style = 'expanded';
   }
   die("Invalid type! Must be one of these: expanded nested compressed compact") unless grep { $_ eq $output_style} qw(expanded nested compressed compact); 
	
   my $psass;	
   die("For your Operation System, you have to specify the psass command location.") unless $psass  = $SASS_CONF{command} ? 
		$SASS_CONF{command} : $command{get_operating_system()};	  
    
   if(! is_file($psass) ) {	
      Rex::Logger::info("Can't find command $psass - it's required an initial setup. First execute setup task to install libSass - CSS::Sass", "error");
      die("Can't execute psass command");
   } else {	
      Rex::Logger::debug("Parsing Sass file");
      my $output = run $psass . ' ' . $source_file . ' -t '.$output_style. ' -o '. $output_file;
      Rex::Logger::debug($output);
      die("Error running psass command.") unless ($? == 0);
   }

};

1;

=pod

=head1 NAME

$::module_name - {{ SHORT DESCRIPTION }}

=head1 DESCRIPTION

{{ LONG DESCRIPTION }}

=head1 USAGE

{{ USAGE DESCRIPTION }}

 require qw/Rex::CSS::Sass/;

 # this task wraps:
 #  psass style.scss -o style.css -t compressed
 #  -o output/file
 #  -t expanded|nested|compressed|compact
 
 task mytask => sub {
    Rex::CSS::Sass::setup();
	
	# you can define a different location for Perl Sass using this command
    set sass => command => "/usr/local/bin/psass.pl";
	
    Rex::CSS::Sass::parseFile('/path/file.scss', {
			output => '/path/file.css',
			type => 'compressed',
		});
 };

=head1 TASKS

=over 4

=item setup

This task will install the required libraries for parsing Sass files.

=item parseFile

This task will parse Sass files and retrive the parsed output.

=back

=cut
