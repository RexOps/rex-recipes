
package Rex::Database::MySQL::Admin::Replication;

use strict;
use warnings;

use Rex -base;
use Rex::Commands::Service;
use Rex::Database::MySQL::Admin;

use Data::Dumper;

my %MYSQL_REPLICATION_CONF = ();

Rex::Config->register_set_handler("mysql_replication" => sub {
	my ($name, $value) = @_;
	$MYSQL_REPLICATION_CONF{$name} = $value;
});

task set_read_only => sub {

	my $params = shift;

	my $readonly = Rex::Database::MySQL::Admin::get_variable('read_only');

	if ($readonly && $readonly eq 'ON') {

		Rex::Logger::info("read_only setting is already enabled - nothing to do");

		return 1;
	}

	# configure mysql
	my $config_file = "/etc/mysql/conf.d/read_only.cnf";

	my $config_content = <<__EOF__;
[mysqld]
read_only = true
__EOF__

	$config_content .= "bind-address = 127.0.0.1\n" if $params->{BindToLocalhost};

	my $remote_config = run("cat $config_file");

	if ($remote_config eq $config_content) {

		Rex::Logger::info("file exists - read_only config file: $config_file");
	}
	else {
		Rex::Logger::info("Writing read_only config file: $config_file");

		file $config_file,
			owner => "root",
			mode => 644,
			content => $config_content,

		Rex::Database::MySQL::Admin::execute({ sql => "FLUSH TABLES WITH READ LOCK; SET GLOBAL read_only = ON;" });
	}

	$readonly = Rex::Database::MySQL::Admin::get_variable('read_only');

	if ($readonly && $readonly eq 'ON') {

		Rex::Logger::info("read_only setting enabled");
	}
	else {
		Rex::Logger::info("Failed to set read_only variable", 'error');
	}

	if ($params->{BindToLocalhost}) {

		my $netstat = run('netstat -tlpn | grep mysqld');
		if ($netstat =~ /127\.0\.0\.1\:3306/) {
			Rex::Logger::info("Listening on localhost");
		}
		else {
			Rex::Logger::info("Still listening on network address: $netstat", 'error');
		}
	}

	Rex::Logger::info("Done");
};

task set_read_write => sub {

	my $params = shift;

	my $config_file = "/etc/mysql/conf.d/read_only.cnf";

	my $readonly = Rex::Database::MySQL::Admin::get_variable('read_only');

	if (!$readonly || $readonly eq 'OFF') {

		Rex::Logger::info("read_only is not set - nothing to do");
		return 1;
	}

	# use config file to persist settings after a reboot
	if (is_file($config_file)) {

		Rex::Logger::info("Removing readonly config file: etc/mysql/conf.d/readonly.cnf");
		unlink($config_file);
	}
	else {
		Rex::Logger::info("Can't find config file: etc/mysql/conf.d/readonly.cnf - skipping");
	}

	# set config dynamically
	Rex::Database::MySQL::Admin::execute({ sql => "SET GLOBAL read_only = OFF; UNLOCK TABLES;" });

	$readonly = Rex::Database::MySQL::Admin::get_variable('read_only');

	if (!$readonly || $readonly eq 'OFF') {

		Rex::Logger::info("read_only setting disabled");
	}
	else {
		Rex::Logger::info("Failed to disable read_only variable", 'error');
	}

	if ($params->{BindToLocalhost}) {

		# did we get a race condition?
		sleep 1;
		my $netstat = run('netstat -tlpn | grep mysqld');

		if ($netstat =~ /127\.0\.0\.1\:3306/) {
			Rex::Logger::info("Still listening on localhost: $netstat", 'error');
		}
		else {
			Rex::Logger::info("Listening on network address");
		}
	}

	Rex::Database::MySQL::Admin::run('flush-logs');

	Rex::Logger::info("Done");
};

task promote_master => sub {

	my $params = shift;

	my $server_id = $params->{server_id} || 1;
	my $log_bin   = $params->{log_bin}   || '/var/log/mysql/mysql-bin.log';

	# configure mysql
	my $config_file = "/etc/mysql/conf.d/replication_master.cnf";

	Rex::Logger::info("Writing master config file: $config_file");

	file $config_file,
		owner => "root",
		mode => 644,
		content => <<__EOF__;
[mysqld]
server-id               = $server_id
log_bin                 = $log_bin
expire_logs_days        = 10
max_binlog_size         = 100M
__EOF__

	# restart mysql
	Rex::Logger::info("Restarting MySQL Server");
	service mysql => "restart";

	my $master_status = get_master_status();

	if ($master_status->{File}) {

		Rex::Logger::info("Got Master binlog file: $master_status->{File}");
	}
	else {

		Rex::Logger::info("Failed to get Master binlog file", 'error');
	}

	if ($master_status->{Position} && $master_status->{Position} =~ /^\d+$/) {

		Rex::Logger::info("Got Master binlog position: $master_status->{Position}");
	}
	else {

		Rex::Logger::info("Failed to get Master binlog position", 'error');
	}
};

task demote_master => sub {

	# configure mysql
	my $config_file = "/etc/mysql/conf.d/replication_master.cnf";

	if (is_file($config_file)) {

		Rex::Logger::info("Removing master config file: $config_file");
		unlink($config_file);
	}
	else {

		die "Master config file not found - giving up";
	}

	# restart mysql
	Rex::Logger::info("Restarting MySQL Server");
	service mysql => "restart";
	#run('/etc/init.d/mysql restart');

	my $master_status = get_master_status();

	if ($master_status->{File}) {

		Rex::Logger::info("DB still appears to be a master", 'error');
		return 0;
	}
	else {

		Rex::Logger::info("DB has no master status");
		return 1;
	}
};

task get_master_status => sub {

	my $result = Rex::Database::MySQL::Admin::execute({ sql => 'SHOW MASTER STATUS \G', quiet => 1 });

	my @matches = $result =~ /^\s*(\w+): (.+)$/mg;

	return { @matches };
};

task get_slave_status => sub {

	my $result = Rex::Database::MySQL::Admin::execute({ sql => 'SHOW SLAVE STATUS \G', quiet => 1 });

	my @matches = $result =~ /^\s*(\w+): (.+)$/mg;

	return { @matches };
};

task init_slaves => sub {

	my $master          = $MYSQL_REPLICATION_CONF{master};
	my $slaves          = $MYSQL_REPLICATION_CONF{slaves};

	#warn "MASTER: " . Dumper($master);
	#warn "SLAVES: " . Dumper($slaves);

	# check / autogenerate slave passwords
	foreach my $slave (@$slaves) {

		unless ($slave->{master_pass}) {

			Rex::Logger::info("Generating password for slave: $slave->{host} [$slave->{ip_addr}]");
			$slave->{master_pass} = _randomPassword(20);
		}
	}

	Rex::Logger::info("Creating master login permissions");
	my $task = Rex::TaskList->create()->get_task("Database:MySQL:Admin:Replication:create_slave_login");
	my $master_status = $task->run($master->{host}, params => $slaves );

	foreach my $slave (@$slaves) {

		Rex::Logger::info("Initialising slave: $slave->{host}");

		# in the next release run_task should accept params
		# my $result = run_task("Rex:Database:MySQL:Admin:Replication:init_slave", on => $slave->{host});

		# meanwhile use this workaround
		my $task = Rex::TaskList->create()->get_task("Database:MySQL:Admin:Replication:init_slave");
		my $result = $task->run($slave->{host}, params => {
			server_id 					=> $slave->{server_id},
			bind_address 				=> $slave->{ip_addr},
			master_host					=> $master->{ip_addr},
			master_user 				=> $slave->{master_user},
			master_pass 				=> $slave->{master_pass},
			master_log_file			=> $master_status->{File},
			master_log_pos				=> $master_status->{Position},
		});

		#warn "RESULT: " . Dumper($result);
	}

};

# basic config required before mysqlreplicate will run
task init_slave => sub {

	my $params = shift || {};

	my $server_id    = $params->{server_id};
	my $bind_address = $params->{bind_address};

	my $master_host     = $params->{master_host} || $MYSQL_REPLICATION_CONF{master}->{ip_addr};
	my $master_user     = $params->{master_user} || 'repl';
	my $master_pass     = $params->{master_pass};
	my $master_log_file = $params->{master_log_file};
	my $master_log_pos  = $params->{master_log_pos};

	die "Need a server_id - giving up"    unless $server_id;
	die "Need a bind_address - giving up" unless $bind_address;
	die "Need a master_host - giving up"  unless $master_host;

	# configure mysql
	my $replication_config_file = "/etc/mysql/conf.d/replication_slave.cnf";

	Rex::Logger::info("Writing slave replication config file: $replication_config_file");

	file $replication_config_file,
		owner => "root",
		mode => 644,
		content => <<__EOF__;
[mysqld]
server-id = $server_id
read-only = true
replicate-ignore-db = mysql
__EOF__

	my $networking_config_file = "/etc/mysql/conf.d/networking.cnf";

	Rex::Logger::info("Writing slave networking config file: $networking_config_file");

	file $networking_config_file,
		owner => "root",
		mode => 644,
		content => <<__EOF__;
[mysqld]
bind-address = $bind_address
__EOF__

	# restart mysql
	Rex::Logger::info("Restarting MySQL Server");
	service mysql => "restart";

	stop_slave();

	Rex::Logger::info("Resetting Slave");
	Rex::Database::MySQL::Admin::execute({	sql => "RESET SLAVE;"});

	Rex::Logger::info("Setting Master host: $master_host");
	Rex::Database::MySQL::Admin::execute({	sql => "CHANGE MASTER TO master_host='$master_host';"	});

	if ($master_user && $master_pass) {

		Rex::Logger::info("Setting Master user & password: $master_user, $master_pass");
		Rex::Database::MySQL::Admin::execute({	sql => "CHANGE MASTER TO master_user='$master_user', master_password='$master_pass';" });
	}

	if ($master_log_file && $master_log_pos) {

		Rex::Logger::info("Setting Master binlog file & position: $master_log_file, $master_log_pos");
		Rex::Database::MySQL::Admin::execute({	sql => "CHANGE MASTER TO master_log_file='$master_log_file', master_log_pos=$master_log_pos;" });
	}

	return start_slave();
};

task start_slave => sub {

	Rex::Database::MySQL::Admin::mysqladmin({ command => "start-slave" });

	my $slave_status_before = get_slave_status();

warn "STATUS BEFORE START SLAVE::: " . Dumper($slave_status_before);

	if ($slave_status_before->{Slave_SQL_Running} ~~ 'Yes' && $slave_status_before->{Slave_IO_Running} ~~ 'Yes') {

		Rex::Logger::info("Slave already running - skipping start slave");
		return 1;
	}

	Rex::Logger::info("Starting slave");
	Rex::Database::MySQL::Admin::mysqladmin({ command => "start-slave" });

	my $slave_status_after = get_slave_status();

	if ($slave_status_after->{Slave_SQL_Running} ~~ 'Yes' && $slave_status_after->{Slave_IO_Running} ~~ 'Yes') {

		Rex::Logger::info("Slave running OK");
		return 1;
	}
	else {
		die "Failed to start slave";
	}
};

task stop_slave => sub {

	my $slave_status_before = get_slave_status();

	if ($slave_status_before->{Slave_SQL_Running} ~~ 'Yes' || $slave_status_before->{Slave_IO_Running} ~~ 'Yes') {

		Rex::Logger::info("Stopping slave");
		Rex::Database::MySQL::Admin::mysqladmin({ command => "stop-slave" });

		my $slave_status_after = get_slave_status();

		die "Failed to stop slave" unless $slave_status_after->{Slave_SQL_Running} ~~ 'No' && $slave_status_after->{Slave_IO_Running} ~~ 'No';
	}
	else {
		Rex::Logger::info("Slave not running");
	}

	# Safely Disable Replication on reboot
	#"CHANGE MASTER TO master_host='';"

};

task create_slave_login => sub {

	my $params = shift || {};

	# handle multiple slaves in one call
	$params = [ $params ] unless ref($params) eq 'ARRAY';

	foreach my $slave (@$params) {

		my $master_user = $slave->{master_user} || 'repl';
		my $master_pass = $slave->{master_pass};
		my $slave_host  = $slave->{ip_addr};

		die "Need a master_pass - giving up" unless $master_pass;
		die "Need a slave_host - giving up" unless $slave_host;

	# why no work??
	#	Rex::Database::MySQL::Admin::User->create({
	#		name		=> $master_user,
	#		password => $master_pass,
	#		host		=> $slave_host,
	#		rights 	=> 'REPLICATION SLAVE',
	#		schema	=> '*.*',
	#	});

		Rex::Database::MySQL::Admin::execute({sql => "GRANT REPLICATION SLAVE ON *.* TO '$master_user'\@'$slave_host' IDENTIFIED BY '$master_pass';\nFLUSH PRIVILEGES;\n"});
	}

	# send back binlog position as most likely we're initialising replication
	return get_master_status();
};

task test_replication => sub {

	my $master          = $MYSQL_REPLICATION_CONF{master};
	my $slaves          = $MYSQL_REPLICATION_CONF{slaves};

	#warn "MASTER: " . Dumper($master);
	#warn "SLAVES: " . Dumper($slaves);

	my $key = time; # use current timestamp as a simple unique key

	my $errors = 0;

	my $task = Rex::TaskList->create()->get_task("Database:MySQL:Admin:Replication:test_replication_master");
	my $result = $task->run($master->{host}, params => { key => $key });

	$errors++ unless $result;

	foreach my $slave (@$slaves) {

		Rex::Logger::info("Initialising slave: $slave->{host}");

		# in the next release run_task should accept params
		# my $result = run_task("Rex:Database:MySQL:Admin:Replication:test_replication_slave", on => $slave->{host}, params => { key => $key });

		# meanwhile use this workaround
		my $task = Rex::TaskList->create()->get_task("Database:MySQL:Admin:Replication:test_replication_slave");
		my $result = $task->run($slave->{host}, params => { key => $key });

		$errors++ unless $result;
	}

	Rex::Logger::info("Replication Test Result: " . ($errors ? 'FAIL' : 'PASS'));

	return $errors ? 0 : 1;
};

task test_replication_master => sub {

	my $params = shift;

	my $key    = $params->{key};

	die "Need a key - giving up" unless $key;

	my $check1 = Rex::Database::MySQL::Admin::execute({ sql => "SHOW DATABASES LIKE 'test';" });

	if ($check1) {
		Rex::Logger::info("Database 'test' exists on master");
	}
	else {
		Rex::Database::MySQL::Admin::execute({ sql => "CREATE DATABASE test;" });

		my $check2 = Rex::Database::MySQL::Admin::execute({ sql => "SHOW DATABASES LIKE 'test';" });

		if ($check2) {
			Rex::Logger::info("Created database 'test' on master");
		}
		else {
			Rex::Logger::info("Failed to create database 'test' on master", 'error');
			return 0;
		}
	}

	my $check3 = Rex::Database::MySQL::Admin::execute({ sql => "SHOW TABLES FROM test LIKE 'replication_test';" });

	if ($check3) {
		Rex::Logger::info("Table 'replication_test' exists on master");
	}
	else {
		Rex::Database::MySQL::Admin::execute({ sql => "CREATE TABLE test.replication_test (id INT AUTO_INCREMENT PRIMARY KEY, data varchar(20), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP());" });

		my $check4 = Rex::Database::MySQL::Admin::execute({ sql => "SHOW TABLES FROM test LIKE 'replication_test';" });

		if ($check4) {
			Rex::Logger::info("Created table 'replication_test' on master");
		}
		else {
			Rex::Logger::info("Failed to create table 'replication_test' on master", 'error');
			return 0;
		}
	}

	Rex::Database::MySQL::Admin::execute({ sql => "INSERT INTO test.replication_test (data) values ('$key');" });

	my $result = Rex::Database::MySQL::Admin::execute({ sql => "select id from test.replication_test where data = '$key' \\G" });

	if ($result =~ /id: (\d+)/m) {

		Rex::Logger::info("Got id: $1 on master");
		return 1;
	}
	else {
		Rex::Logger::info("Failed to read id back from table 'replication_test' on master", 'error');
		return 0;
	}
};

task test_replication_slave => sub {

	my $params = shift;

	my $key    = $params->{key};

	die "Need a key - giving up" unless $key;

	my $result = Rex::Database::MySQL::Admin::execute({ sql => "select id from test.replication_test where data = '$key' \\G" });

	if ($result =~ /id: (\d+)/m) {

		Rex::Logger::info("Got id: $1 on slave");
		return 1;
	}
	else {
		Rex::Logger::info("Failed to read id back from table 'replication_test' on slave", 'error');
		return 0;
	}

};

sub _randomPassword {

	my $password_length = shift || 10;

	my ($password, $_rand);

	my @chars = ('a'..'z', 'A'...'Z', 0..9);

	srand;

	for (my $i=1; $i <= $password_length ;$i++) {
		$_rand = int(rand scalar @chars);
		$password .= $chars[$_rand];
	}
	return $password;
}

1;


=pod

=head1 NAME

Rex::Database::MySQL::Admin::Replication - Manage your MySQL Replication Master and Slave servers

=head1 USAGE

set mysql => defaults_file => '/etc/mysql/debian.cnf';

# put your server in this group

set group mysql_master => "db-test-master";
set group mysql_slaves => "db-test-slave", "db-test-slave2";

# we need additional info about the master and slaves, so configure those here
set mysql_replication => master => {
	server_id 	=> 1,
	host 			=> 'db-test-master',
	ip_addr		=> '192.168.0.100',
};

set mysql_replication => slaves => [
	{
		server_id 	=> 2,
		host 			=> 'db-test-slave',
		ip_addr		=> '192.168.0.101',
		#master_user => 'repl',
		#master_pass => 'autogen',
	},
	{
		server_id 	=> 3,
		host 			=> 'db-test-slave2',
		ip_addr		=> '192.168.0.102',
		#master_user => 'repl',
		#master_pass => 'autogen',
	},
];

sudo -on;

task "mysql_read_only", group => "mysql_master", sub {

	Rex::Database::MySQL::Admin::Replication::set_read_only();
};

task "mysql_read_write", group => "mysql_master", sub {

	Rex::Database::MySQL::Admin::Replication::set_read_write();
};

task "mysql_promote_master", group => "mysql_master", sub {

	Rex::Database::MySQL::Admin::Replication::promote_master();
};

task "mysql_demote_master", group => "mysql_master", sub {

	Rex::Database::MySQL::Admin::Replication::demote_master();
};

task "mysql_stop_slave", group => "mysql_slaves", sub {

	Rex::Database::MySQL::Admin::Replication::stop_slave();
};

task "mysql_init_slaves", sub {

	Rex::Database::MySQL::Admin::Replication::init_slaves();
};

task "mysql_test_replication", sub {

	Rex::Database::MySQL::Admin::Replication::test_replication();
};


