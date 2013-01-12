package nginx;

use Rex -base;


####################################################
# private default variables
my $template = "templates/vhost.tpl";

my $sites_available = "/etc/nginx/sites-available/";
my $sites_enabled = "/etc/nginx/sites-enabled/";

my $root = "/var/www/";
my $ip = "";
my $port = 80;


####################################################
# START
desc "starts the nginx service";
task "start" => make {
	if ( service nginx => "start" ) {
		say "nginx started!";
	} else {
		if( service nginx => "status" ) {
			say "nginx is already running!";
		} else {
			say "nginx could not be started!";
	    }
	}
};

####################################################
# RELOAD
desc "reloads the nginx configuration";
task "reload" => make {
	if (service nginx => "reload" ) {
		say "nginx reloaded!";
	} else {
		say "nginx could not be reloaded!";
	}
};

####################################################
# RESTART
desc "restarts the nginx service";
task "restart" => make {
	if ( service nginx => "restart" ) {
		say "nginx restarted!";
	} else {
		say "nginx could not be restarted!";
	}
};

####################################################
# STOP
desc "stops the nginx service";
task "stop" => make {
	if ( service nginx => "stop" ) {
		say "nginx stopped!";
	} else {
		say "nginx could not be stopped!";
	}
};

####################################################
# STATUS
desc "checks the nginx service status";
task "status" => make {
	if( service nginx => "status" ) {
		say "nginx is running!";
	} else {
		say "nginx is not running!";
    }
};


####################################################
# CREATE
desc "creates a new virtual host";
task "create" => make {

	# store all parameters in $param
	my $param = shift;

	# check if params are defined
	if( is_defined("name", $param) && is_defined("domain", $param) && $param->{name} ne "" && $param->{domain} ne "" ) {

	    # check if a port to listen on is set (if not -> default)
		if ( !is_defined("port", $param) ) {
			$param->{port} = $port;
		}

		# check if a root directory has been defined (if not -> default)
		if ( !is_defined("root", $param) ) {
			$param->{root} = $root . $param->{domain};
		}

		# check if a template has been defined (if not -> default)
		if ( is_defined("template", $param) ) {
			$template = "templates" . $param->{template} . ".tpl";
		}

		# check for additional server_name aliases
		if ( is_defined("aliases", $param) ) {
			# create an array of aliases
 			my @aliases = split(',', $param->{aliases});
 			$param->{aliases} = "";

			# create the server_name string
			foreach my $alias (@aliases) {
				$param->{aliases} .= $alias . " ";
			}
		}
		$param->{aliases} .= $param->{domain};

		# check if we bind the vhost to an IP
		if ( is_defined("bind", $param) ) {
			$param->{ip} = $param->{bind} . ":";
		} else {
			$param->{ip} = $ip;
		}

	    # path of the vhost to be created
	    my $vhost = $sites_available . $param->{name};

	    # check if vhost already exists
	    if( is_file($vhost) ) {
	    	abort($vhost . " already exists!");
	    }

	    # check if $sites_available is a directory
	    if( is_dir($sites_available) ) {

	    	# check if it's writable
	    	if ( is_writable($sites_available) ) {

	    		# create the vhost file based on the template
			    file "$vhost",
			    	content => template($template, %{ $param }),
			    	owner   => "root",
			    	group   => "root",
			    	mode    => 644
			    ;

			    # validate file creation
			    if( is_file($vhost) ) {
			    	say "Created successfully!";
			    } else {
			    	say "Something went wrong...";
			    }

	    	} else {
	    		abort($sites_available . " is not writable!");
    		}

	    } else {
	    	abort($sites_available . " is not a directory!");
	    }

	} else {

		# is it name that is not defined?
		if ( !is_defined("name", $param) || $param->{name} eq "" ) {
			say "Name needs to be defined!";
		}

		# is it domain that is not defined?
		if ( !is_defined("domain", $param) || $param->{domain} eq "" ) {
			say "Domain needs to be defined!";
		}

		abort("Full call should look like: rex nginx:create --name=domain --domain=domain.tld\nOptional parameters are --root=/var/www/domain.tld --template=socket --enable=true --port=82 --bind=127.0.0.1 --aliases=www.domain.tld,otherdomain.tld");

	}

};

####################################################
# DELETE
desc "deletes a virtual host";
task "delete" => make {

	# store all parameters in $param
	my $param = shift;

	# check if name is defined
	if( is_defined("name", $param) && $param->{name} ne "" ) {

		# path of the vhost to be created
	    my $vhost = $sites_available . $param->{name};

 		# check if vhost exists
	    if( is_file($vhost) ) {

	    	# directory writable?
	    	if ( is_writable($sites_available) ) {

	    		# remove the vhost
		    	unlink($vhost);

		    	# check success
		    	if ( !is_file($vhost) ) {
		    		say "Deleted successfully!";
		    	} else {
		    		say "Something went wrong...";
		    	}

	    	} else {
	    		abort($sites_available . " is not writable!");
	    	}

	    } else {
	    	abort($vhost . " does not exist!");
    	}

	} else {
		abort("Name must be defined: --name=domain");
	}

};

####################################################
# ENABLE
desc "enables a virtual host";
task "enable" => make {

	# store all parameters in $param
	my $param = shift;

	# check if name has been defined
	if ( is_defined("name", $param) && $param->{name} ne "" ) {

		# path of the vhost to be enabled
	    my $vhost = $sites_available . $param->{name};

		# check if vhost exists
		if ( is_file($vhost) ) {

			# check if directory for enabled vhosts exists
			if ( is_dir($sites_enabled) ) {

				# check if dir is writable
				if ( is_writable($sites_enabled) ) {

					# create the symlink (like ln -s)
					my $vhost_enabled = $sites_enabled . $param->{name};
					ln($vhost, $vhost_enabled);

					# check if symlink was created
					my $ln;
				    eval {
				    	$ln = readlink($vhost_enabled);
				    };
				    if ($ln) {
				    	say "Enabled successfully!";
				    } else {
				    	say "Something went wrong...";
				    }

				} else {
					abort($sites_enabled . " is not writable!");
				}

			} else {
				abort($sites_enabled . " is not a directory!");
			}

		} else {
			abort($vhost . " does not exist!");
		}

	} else {
		abort("Name must be defined: --name=domain");
	}

};

####################################################
# DISABLE
desc "disables a virtual host";
task "disable" => make {

	# store all parameters in $param
	my $param = shift;

	# check if name has been defined
	if ( is_defined("name", $param) && $param->{name} ne "" ) {

		# path of the vhost to be enabled
	    my $vhost = $sites_enabled . $param->{name};

		# check if symlink exists
		my $ln;
		eval {
			$ln = readlink($vhost);
		};
		if ($ln) {

			# check if dir is writable
			if ( is_writable($sites_enabled) ) {

				# remove the symlink
				unlink($vhost);

				# check if symlink was deleted
				eval {
					$ln = readlink($vhost);
				};
				if ($ln) {
					say "Disabled successfully!";
				} else {
					say "Something went wrong...";
				}

			} else {
				abort($sites_enabled . " is not writable!");
			}

		} else {
			abort($vhost . " does not exist!");
		}

	} else {
		abort("Name must be defined: --name=domain");
	}

};


####################################################
# AVAILABLE
desc "lists all available virtual hosts";
task "available" => make {
	for my $file (list_files( $sites_available )) {
		if ($file ne "." && $file ne "..") {
			say "$file";
		}
	}
};

####################################################
# ENABLED
desc "lists all enabled virtual hosts";
task "enabled" => make {
	for my $file (list_files( $sites_enabled )) {
		if ($file ne "." && $file ne "..") {
			say "$file";
		}
	}
};

####################################################
# DISABLED
desc "lists all disabled virtual hosts";
task "disabled" => make {
	my $vhost;
	my $ln;

	for my $file (list_files( $sites_available )) {
		if ($file ne "." && $file ne "..") {

			# vhost enabled
			$vhost = $sites_enabled . $file;

			# check if a symlink exists for the vhost
			eval {
				$ln = readlink($vhost);
			};
			if (!$ln) {
				say $file;
			}

		}
	}
};


####################################################
# HOOK: AFTER CREATE
after "create" => make {
	my ($server, $failed) = @_;
	my $param = { Rex::Args->get };

	# check if main task ended successfully
	if(! $failed) {
		# check if sites shall be enabled afterwards
		if ( is_defined("enable", $param) && $param->{enable} eq "true" ) {
		 	run_task "nginx:enable", on => $server;
		}
	}
};

####################################################
# HOOK: BEFORE DELETE
before "delete" => make {
	my ($server, $failed) = @_;
	my $param = { Rex::Args->get };

	run_task "nginx:disable", on => $server;
};

####################################################
# HOOK: AFTER ENABLE
after "enable" => make {
	my ($server, $failed) = @_;
	my $param = { Rex::Args->get };

	# check if main task ended successfully
	if(! $failed) {
		 run_task "nginx:reload", on => $server;
	}
};

####################################################
# HOOK: AFTER DISABLE
after "disable" => make {
	my ($server, $failed) = @_;
	my $param = { Rex::Args->get };

	# check if main task ended successfully
	if(! $failed) {
		 run_task "nginx:reload", on => $server;
	}
};


####################################################
# checks if a key exists in haystack
# e.g. to check if a param is defined
# is_defined("domain", $param)
# @return boolean
sub is_defined {
	my ($key, $haystack) = @_;
	if (exists $haystack->{$key}) {
		return 1;
	}
}

####################################################
# aborts the task execution
# e.g. if a requirement isn't met
# abort("Message to display before aborting.");
sub abort {
	my $message = $_[0];
	say $message;
	say "Aborting...";
	exit;
}


1;


=pod

=head1 NAME

Rex::Webserver::nginx - Module to manage nginx webserver

=head2 USAGE

Put it in your I<Rexfile>

 require nginx;

And call it:

 rex -H $host nginx:task

Or, to use it as a library

 task "yourtask", sub {
    nginx::task();
 };

 require nginx;

=head2 TASKS

=item available

This task lists all available virtual hosts.

=item create

This task creates a new virtual host.

=item delete

This task deletes a virtual host.

=item disable

This task disables a virtual host.

=item disabled

This task lists all disabled virtual hosts.

=item enable

This task enables a virtual host.

=item enabled

This task lists all enabled virtual hosts.

=item reload

This task reloads the nginx configuration.

=item restart

This task restarts the nginx service.

=item start

This task starts the nginx service.

=item status

This task checks the nginx service status.

=item stop

This task stops the nginx service.