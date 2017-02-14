#
# AUTHOR: Paulo Graça <paulo1978@gmail.com>
# REQUIRES: Rex::CMS::WP_CLI
# LICENSE: MIT
# 
# Module to manage Wordpress plugins.

package Rex::CMS::WP_CLI::Plugin;

use strict;
use warnings;

use Rex::Commands;
use Rex::CMS::WP_CLI;

our $WP_CLI_COMMAND = 'plugin';

task "activate" => sub {
   _execute(task->name, @_);
};

task "deactivate" => sub {
   _execute(task->name, @_);
};

task "delete" => sub {
   _execute(task->name, @_);
};

task "install" => sub {   
   _execute(task->name, @_);
};

task "uninstall" => sub {
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
Rex::CMS::WP_CLI::Plugin - Wordpress CLI Plugin module for Rex, it permits to manage Wordpress Plugins through the Command-Line Interface
=head1 USAGE
Use it in a task
 use Rex::CMS::WP_CLI::Plugin;
     
 # Set default base_dir
 set wp_cli => base_dir => '/var/www/html';
 
 task "prepare", sub {
    # it will install the bbpress plugin
    Rex::CMS::WP_CLI::Plugin::install('bbpress');

    # it will install and activate the bbpress plugin
    Rex::CMS::WP_CLI::Plugin::install('bbpress --activate');
 };

=head1 TASKS

=over 4

=item install
  It will install a plugin <plugin|zip|url>

=item uninstall
  It will uninstall a plugin

=item delete
  It will delete a Plugin
  
=item activate
  It will activate an installed Plugin

=item deactivate
  It will deactivate an installed Plugin
 
=item update
  It will update an installed Plugin

1;