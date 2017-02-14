#
# AUTHOR: Paulo Graça <paulo1978@gmail.com>
# REQUIRES: Rex::CMS::WP_CLI
# LICENSE: MIT
# 
# Module to manage Wordpress core instalation.

package Rex::CMS::WP_CLI::Core;

use strict;
use warnings;

use Rex::Commands;
use Rex::CMS::WP_CLI;

our $WP_CLI_COMMAND = 'core';

task "download" => sub {
   _execute(task->name, @_);
};

task "install" => sub {
   _execute(task->name, @_);
};

task "update" => sub {
   _execute(task->name, @_);
};

task "update_db" => sub {
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
Rex::CMS::WP_CLI::Core - Wordpress CLI Core module for Rex, it permits to manage Wordpress install through the Command-Line Interface
=head1 USAGE
Use it in a task
 use Rex::CMS::WP_CLI::Core;
     
 # Set default base_dir
 set wp_cli => base_dir => '/var/www/html';
 
 task "prepare", sub {
    Rex::CMS::WP_CLI::Core::install('--url=example.com --title=Example --admin_user=supervisor --admin_password=strongpassword --admin_email=info@example.com');
 };

=head1 TASKS

=over 4

=item install
  Runs the standard WordPress installation process (it requires to first execute "download" task)

=item download
  It will download and extract WordPress core files
  
=item update
  It will update a Wordpress installation site
 
=item update_db
  It will update the Wordpress Database

1;