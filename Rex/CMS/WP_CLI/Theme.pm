#
# AUTHOR: Paulo Graça <paulo1978@gmail.com>
# REQUIRES: Rex::CMS::WP_CLI
# LICENSE: MIT
# 
# Module to manage Wordpress themes.

package Rex::CMS::WP_CLI::Theme;

use strict;
use warnings;

use Rex::Commands;
use Rex::CMS::WP_CLI;

our $WP_CLI_COMMAND = 'theme';

task "activate" => sub {
  _execute(task->name, @_);
};

task "delete" => sub {
   _execute(task->name, @_);
};

task "install" => sub {
   _execute(task->name, @_);
};

task "update" => sub {
   _execute(task->name, @_);
};

sub _execute {
   my ($task_name, $params) = @_;
   my @action = split(/\:/, $task_name);   
   
   Rex::CMS::WP_CLI::execute('', {
		  command => $WP_CLI_COMMAND,
		  action => $action[$#action],
		  parameters => $params,
		}
   );
};


=pod
=head1 NAME
Rex::CMS::WP_CLI::Theme - Wordpress CLI Theme module for Rex, it permits to manage Wordpress Themes through the Command-Line Interface
=head1 USAGE
Use it in a task
 use Rex::CMS::WP_CLI::Theme;
     
 # Set default base_dir
 set wp_cli => base_dir => '/var/www/html';
 
 task "prepare", sub {
    Rex::CMS::WP_CLI::Theme::install('twentysixteen');
 };

=head1 TASKS

=over 4

=item install
  It will install a Theme <theme|zip|url>

=item delete
  It will delete a Theme
  
=item activate
  It will activate an installed Theme
 
=item update
  It will update an installed Theme

1;