server {

	######################################################################
	## Server configuration
	######################################################################

	# Tell nginx to listen on port 80 (default http port, IPv4)
	listen <%= $::ip %><%= $::port %>;

	# name-based virtualhost
	server_name <%= $::aliases %>;

	# set the document root
	root <%= $::root %>;

	######################################################################
	## Log configuration
	######################################################################

	access_log /var/log/nginx/<%= $::name %>.log;
	error_log /var/log/nginx/<%= $::name %>.log;

	######################################################################
	## Locations configuration
	######################################################################

	location ~ /\. {

		# Don't allow any access
		deny all;

		# Don't log access
		access_log off;

	}

}