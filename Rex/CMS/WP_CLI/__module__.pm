#
# AUTHOR: Paulo Graça <paulo1978@gmail.com>
# REQUIRES:
# LICENSE: MIT
# 
# Module to install WP_CLI and to execute commands


package Rex::CMS::WP_CLI;

use strict;
use warnings;

# REX dependencies
use Rex -base;

use Rex::Logger;
use Rex::Config;

use Data::Dumper;

my %WP_CLI_CONF = ();

Rex::Config->register_set_handler("wp_cli" => sub {
   my ($name, $value) = @_;
   $WP_CLI_CONF{$name} = $value;
});

set wp_cli => source => "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar";
set wp_cli => target => "/usr/local/wordpress/wp-cli";
set wp_cli => symlink => "/usr/local/bin/wp";

desc "Install WordPress CLI tool";
task "setup" => sub {	
	my $target = $WP_CLI_CONF{target};
	my $source = $WP_CLI_CONF{source};
	my $symlink = $WP_CLI_CONF{symlink};
	
	# verify if php is installed
	if(! is_installed("php") ) {
		die("PHP is required.");	   
	}
	
    # Create source dir if it doesn't exists
    file $target, ensure => "directory";

    # download compressed source file
    run 'wget '.$source.' -O '.$target.'/wp-cli.phar';
	chmod 755, $target.'/wp-cli.phar';
	
	if(! is_symlink($symlink) ) {
      ln ($target.'/wp-cli.phar', $symlink);
    }  
	
    Rex::Logger::info("WP-CLI successfully installed");
};

desc "Execute WordPress CLI tool";
task "execute" => sub {
   my $param = shift;  
   my $base_dir;
   my $key = (keys $param)[0];   
   my $symlink = $WP_CLI_CONF{symlink};
   
   die("You have to specify the wp path to execute.") unless $base_dir  = $key ? $key : $WP_CLI_CONF{base_dir};	   
   die("You have to specify the command to execute.") unless $param->{$key}->{command};
   die("You have to specify the action to execute.") unless $param->{$key}->{action};
  
   if(! is_symlink($symlink) ) {
      Rex::Logger::info("WP-CLI requires instalation, first execute setup", "error");
	  die("Can't execute wp-cli");
   } else {
		Rex::Logger::info("Running: wp "
			. $param->{$key}->{command}
			.' '.$param->{$key}->{action}
			.' '.$param->{$key}->{parameters});		
			
		run 'wp '.$param->{$key}->{command}
			.' '.$param->{$key}->{action}
			.' '.$param->{$key}->{parameters} 
			.' --path=' .$base_dir 
		;
		die("Error running wp command. Please check the base_dir param.") unless ($? == 0);
		
   }
};

=pod
=head1 NAME
Rex::CMS::WP_CLI - Wordpress CLI module for Rex, it permits to manage Wordpress install through the Command-Line Interface
=head1 USAGE
 rex -H $host Rex:CMS:WP_CLI:setup
Or, to use it as a library
 use Rex::CMS::WP_CLI;
 
 task "prepare", sub {
    Rex::CMS::WP_CLI::setup();
 };

=head1 TASKS

=over 4

=item setup
  Install WordPress CLI tool
  
=item execute
  This task will execute wp cli commands
     
     # Set default base_dir
	 set wp_cli => base_dir => '/var/www/html';

     task "mytask", sub {
      Rex::CMS::WP_CLI::execute('/path_to_wordpress_website', {
		  command => 'theme',
		  action => 'install',
		  parameters => 'twentysixteen --activate',
		}
	  );
     }; 
 
1;