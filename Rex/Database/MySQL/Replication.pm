#
# AUTHOR: mike tonks <miket@cpan.org>
# REQUIRES: Database::MySQL::Admin
# LICENSE: GPLv3
#
# Manage MySQL Replication for Master and Slave servers.

package Rex::Database::MySQL::Replication;

use strict;
use warnings;

use Rex -base;
use Rex::Commands::Service;
use Rex::Database::MySQL::Admin;
use Rex::Database::MySQL::Replication::ConfigStore;

use Data::Dumper;

# YAML is required to read and write a config file, to maintain the status of master and slave servers
use YAML::Tiny;

my %MYSQL_REPLICATION_CONF = ();

#
Rex::Config->register_set_handler("mysql_replication" => sub {
   my ($name, $value) = @_;
   $MYSQL_REPLICATION_CONF{$name} = $value;
});

task change_master => sub {

   my $params = shift;

   my $new_master_host = connection->server()->{name};

   die 'Please specify new_master' unless $new_master_host;

   die 'Please specify target host' if $new_master_host eq '<local>'; # for now, no real reason why localhost can't be a master

   my $config = _load_config();

   my $master = $config->{master}; # previously configured master
   my $slaves = $config->{slaves}; # previously configured slaves

   # search for new_master in the available slaves
   #my $new_master = $slaves->{$new_master_host};
   #die "New master $params->{new_master} not found in available slaves - please check your config" unless $new_master;

   Rex::Logger::info("CHANGE MASTER: New Master will be $new_master_host");

   # The current master should be is online, make it read only
   # TODO: handle scenario where old master is dead
   # For now, if master is dead / offline, use init_master and init_slave instead (delete your replication.cfg first)
   run_task('Database:MySQL:Replication:set_read_only', on => $new_master_host);

   my $old_master_host = $master->{host};
   my $master_status = run_task('Database:MySQL:Replication:get_master_status', on => $old_master_host);

   Rex::Logger::info("Got OLD Master Status - File: $master_status->{File}, Position: $master_status->{Position}");

   # make sure all slaves are up to date
   foreach my $slave_host (sort keys %$slaves) {

      my $slave_status = 	run_task('Database:MySQL:Replication:get_slave_status', on => $slave_host);

      #say "STATUS: " . Dumper($slave_status);

      die "Slave not running: $slave_host - Slave_IO_Running: $slave_status->{Slave_IO_Running}" unless $slave_status->{Slave_IO_Running} eq 'Yes';
      die "Slave not running: $slave_host - Slave_SQL_Running: $slave_status->{Slave_SQL_Running}" unless $slave_status->{Slave_SQL_Running} eq 'Yes';

      die "Slave not up to date: $slave_host - Seconds_Behind_Master: $slave_status->{Seconds_Behind_Master}" unless $slave_status->{Seconds_Behind_Master} == 0;

      die "Slave not up to date: $slave_host - Relay_Master_Log_File: $slave_status->{Relay_Master_Log_File}" unless $slave_status->{Relay_Master_Log_File} eq $master_status->{File};
      die "Slave not up to date: $slave_host - Exec_Master_Log_Pos: $slave_status->{Exec_Master_Log_Pos}" unless $slave_status->{Exec_Master_Log_Pos} eq $master_status->{Position};

      Rex::Logger::info("OK Slave is up to date: $slave_host");
   }

   # now we need to rejig the settings so we can run init_slaves
   Rex::Logger::info("CHANGE MASTER: Previous Master will become a Slave: $master->{host}");
   delete $master->{server_id};
   $slaves->{$master->{host}} = $master;

   if (exists($slaves->{$new_master_host})) {
      Rex::Logger::info("CHANGE MASTER: Previous Slave will be promoted to Master: $new_master_host");
      delete $slaves->{$new_master_host};
   }

   foreach my $slave_host (sort keys %$slaves) {

      Rex::Logger::info("CHANGE MASTER: Slave will remain a slave: $slave_host");
   }

   # Save the new config before we do anything else
   $config->{master} = { host => $new_master_host };
   $config->{slaves} = $slaves;

   _save_config($config);

   run_task('Database:MySQL:Replication:demote_master', on => $old_master_host);
   run_task('Database:MySQL:Replication:init_master', on => $new_master_host, params => { clean => 1} );

   run_task('Database:MySQL:Replication:init_slaves', on => '<local>');

   Rex::Logger::info("CHANGE MASTER: Changes complete, now test the replication");

   if (run_task('Database:MySQL:Replication:test_replication', on => '<local>')) {

      Rex::Logger::info("CHANGE MASTER: COMPLETED OK");
   }
   else {
      Rex::Logger::info("CHANGE MASTER: FAIL (Something went wrong - please check the logs)");
   }
};

task init_master => sub {

   my $params = shift;

   my $master_host = connection->server()->{name};

   die 'Please specify target host' if $master_host eq '<local>'; # for now, no real reason why localhost can't be a master

   my $server_id   = $params->{server_id}   || 1;
   my $log_bin     = $params->{log_bin}     || '/var/log/mysql/mysql-bin.log';

   my $config = _load_config();

   my $master = $config->{master}; # previously configured master

   if ($master && $master->{host} ne $master_host) {

      Rex::Logger::info("Changing master host from: $master->{host} to $master_host");
      $master->{host} = $master_host;
   }

   Rex::Logger::info("Initializing MySQL Master - server-id: $server_id");
   $master->{server_id} = $server_id;
   $master->{log_bin}   = $log_bin;

   LOCAL {
      $master->{ip_addr}  = _ip_addr($master_host);
   };

   # check for config files created by this module, that might interfere with replication
   foreach my $file (qw/read_only replication_slave/) {

      my $config_file = "/etc/mysql/conf.d/$file.cnf";

      if (is_file($config_file)) {

         if ($params->{clean}) {
            Rex::Logger::info("Removing Config File: $config_file");
            unlink($config_file);
         }
         elsif ($params->{force}) {
            Rex::Logger::info("Suspicious Config File found: $config_file - this could break your replication");
         }
         else {
            die "Suspicious Config File found: $config_file - this could break your replication";
         }
      }
   }

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

      die "Failed to get Master binlog file";
   }

   if ($master_status->{Position} && $master_status->{Position} =~ /^\d+$/) {

      Rex::Logger::info("Got Master binlog position: $master_status->{Position}");
   }
   else {

      die "Failed to get Master binlog position";
   }

   $config->{master} = $master;

   _save_config($config);
};

task demote_master => sub {

   Rex::Logger::info("Demoting MySQL Master");

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

task init_slaves => sub {

   my $config = _load_config();

   my $master = $config->{master};
   my $slaves = $config->{slaves};

   die "Master not configured" unless $master->{host} && $master->{server_id};
   die "Slave not configured" unless scalar keys %$slaves > 0;

   Rex::Logger::info("Reading master status");
   my $master_status = run_task('Database:MySQL:Replication:get_master_status', on => $master->{host} );

   foreach my $slave_host (sort keys %$slaves) {

      my $slave = $slaves->{$slave_host};

      Rex::Logger::info("Initialising slave: $slave->{host}");

      # in the next release run_task should accept params
      my $result = run_task('Database:MySQL:Replication:init_slave', on => $slave->{host}, params => {
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

task init_slave => sub {

   my $params = shift || {};

   # these are the accepted params
   foreach my $param(qw/server_id master_user master_pass test/) {
      Rex::Logger::info("Got Param - $param: $params->{$param}") if $params->{$param};
   }

   die "server-id: 1 is for master only" if $params->{server_id} ~~ '1';

   my $slave_host = connection->server()->{name};

   die 'Please specify target host' if $slave_host eq '<local>'; # for now, no real reason why localhost can't be a slave

   my $config = _load_config();

   my $master = $config->{master}; # previously configured master
   my $slaves = $config->{slaves}; # previously configured master

   my $slave  = $slaves->{$slave_host} || {}; # previously configured slave

   die "Master not configured" unless $master->{host} && $master->{server_id};

   $slave->{server_id}  = $params->{server_id} if $params->{server_id};
   $slave->{host}  = $slave_host;

   LOCAL {
      $slave->{ip_addr}  = _ip_addr($slave_host);
   };

   # generate a server-id if we don't already have one
   unless ($slave->{server_id}) {

      $slave->{server_id} = 2;

      foreach my $_host (sort keys %$slaves) {

         my $existing_slave = $slaves->{$_host};
         $slave->{server_id} = $existing_slave->{server_id} + 1 if $existing_slave->{server_id} && $existing_slave->{server_id} >= $slave->{server_id};
      }

      Rex::Logger::info("Assigning server-id: $slave->{server_id}")
   }

   # generate a login if none exists
   $slave->{master_user} = $params->{master_user} if $params->{master_user};
   $slave->{master_pass} = $params->{master_pass} if $params->{master_pass};

   # use 'repl' as the default user if none specified
   $slave->{master_user} = 'repl' if !$slave->{master_user};

   my $master_status;

   unless ($slave->{master_pass}) {

      Rex::Logger::info("Generating password for slave: $slave->{host} [$slave->{ip_addr}]");
      $slave->{master_pass} = _randomPassword(20);
   }

   # We have all the data now, so save the config
   $slaves->{$slave_host} = $slave;
   $config->{slaves} = $slaves;
   _save_config($config);


   # Make set master login, this return the master status
   Rex::Logger::info("Creating master login permissions");
   $master_status = run_task('Database:MySQL:Replication:create_slave_login', on => $master->{host}, params => $slave );

   if ($master_status->{File}) {

      Rex::Logger::info("Got Master binlog file: $master_status->{File}");
   }
   else {

      die "Failed to get Master binlog file";
   }

   if ($master_status->{Position} && $master_status->{Position} =~ /^\d+$/) {

      Rex::Logger::info("Got Master binlog position: $master_status->{Position}");
   }
   else {

      die "Failed to get Master binlog position";
   }

   # configure mysql
   my $replication_config_file = "/etc/mysql/conf.d/replication_slave.cnf";

   Rex::Logger::info("Writing slave replication config file: $replication_config_file");

   my $replication_config = <<__EOF__;
[mysqld]
server-id = $slave->{server_id}
read-only = true
replicate-ignore-db = mysql
__EOF__

# why is this so slow???
   file $replication_config_file,
      owner => "root",
      mode => 644,
      content => $replication_config;

   my $networking_config_file = "/etc/mysql/conf.d/networking.cnf";

   Rex::Logger::info("Writing slave networking config file: $networking_config_file");

   my $networking_config = <<__EOF__;
[mysqld]
bind-address = $slave->{ip_addr}
__EOF__

   file $networking_config_file,
      owner => "root",
      mode => 644,
      content => $networking_config;

   # restart mysql
   Rex::Logger::info("Restarting MySQL Server");
   service mysql => "restart";

   stop_slave();

   Rex::Logger::info("Resetting Slave");
   Rex::Database::MySQL::Admin::execute({	sql => "RESET SLAVE;"});

   Rex::Logger::info("Setting Master host: $master->{host}, user & password: $slave->{master_user}, *********, binlog file & position: $master_status->{File}, $master_status->{Position}");

   Rex::Database::MySQL::Admin::execute({	sql => "CHANGE MASTER TO master_host='$master->{ip_addr}', master_user='$slave->{master_user}', master_password='$slave->{master_pass}', master_log_file='$master_status->{File}', master_log_pos=$master_status->{Position};" });

   # Seems like at this point the slave will be started automatically, but let's make sure it is
   die "Failed to start slave" unless start_slave();

   # only run tests if explicitly requested
   if ($params->{test}) {
      Rex::Logger::info("Running Replication Test...");

      my $key = run_task('Database:MySQL:Replication:test_replication_master', on => $master->{host});
      my $ok =  run_task('Database:MySQL:Replication:test_replication_slave', params => { key => $key }, on => $slave->{host});

      # NB We shouldn't need the 'on => $slave->{host}' for test_replication_slave ^^  since we're already there, but without it I get a failure as it doesn't sudo the command?

      Rex::Logger::info("Replication Test Result: " . ($ok ? 'PASS' : 'FAIL'));
   }
};

task start_slave => sub {

   Rex::Database::MySQL::Admin::mysqladmin({ command => "start-slave" });

   my $slave_status_before = get_slave_status();

   if ($slave_status_before->{Slave_SQL_Running} ~~ 'Yes' && $slave_status_before->{Slave_IO_Running} ~~ 'Yes') {

      Rex::Logger::info("Slave running - skipping start slave");
      return 1;
   }

   Rex::Logger::info("Starting slave");
   Rex::Database::MySQL::Admin::mysqladmin({ command => "start-slave" });

   my $slave_status_after = get_slave_status();

   if ($slave_status_after->{Slave_SQL_Running} ~~ 'Yes' && $slave_status_after->{Slave_IO_Running} ~~ 'Yes') {

      my $lag = $slave_status_after->{Seconds_Behind_Master};
      Rex::Logger::info("Slave running OK ($lag seconds behind master)");
      Rex::Logger::info("We've got a bit of catching up to do...") if $lag > 60;

      return 1;
   }
   else {
      Rex::Logger::info("Last SQL Error: $slave_status_after->{Last_SQL_Error}") if $slave_status_after->{Last_SQL_Error};
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

   my $config = _load_config();

   my $master = $config->{master};
   my $slaves = $config->{slaves};

   #warn "MASTER: " . Dumper($master);
   #warn "SLAVES: " . Dumper($slaves);

   die "Master not configured" unless $master->{host};# && $master->{server_id};
   die "Slave not configured" unless scalar keys %$slaves > 0;

   Rex::Logger::info("Testing Master: $master->{host}");
   my $key = run_task('Database:MySQL:Replication:test_replication_master', on => $master->{host});

   die "Failed to run master tests, giving up" unless $key;

   my $errors = 0;

   foreach my $slave_host (sort keys %$slaves) {

      my $slave = $slaves->{$slave_host};

      Rex::Logger::info("Testing Slave: $slave->{host}");
      my $result = run_task('Database:MySQL:Replication:test_replication_slave', on => $slave->{host}, params => { key => $key });

      $errors++ unless $result;
   }

   Rex::Logger::info("Replication Test Result: " . ($errors ? 'FAIL' : 'PASS'));

   return $errors ? 0 : 1;
};

task test_replication_master => sub {

   my $params = shift;

   my $key = time; # use current timestamp as a simple unique key

   my $check1 = Rex::Database::MySQL::Admin::execute({ sql => "SHOW DATABASES LIKE 'test';", quiet => 1 });

   if ($check1) {
      Rex::Logger::info("Database 'test' exists on master");
   }
   else {
      Rex::Database::MySQL::Admin::execute({ sql => "CREATE DATABASE test;" });

      my $check2 = Rex::Database::MySQL::Admin::execute({ sql => "SHOW DATABASES LIKE 'test';", quiet => 1 });

      if ($check2) {
         Rex::Logger::info("Created database 'test' on master");
      }
      else {
         Rex::Logger::info("Failed to create database 'test' on master", 'error');
         return 0;
      }
   }

   my $check3 = Rex::Database::MySQL::Admin::execute({ sql => "SHOW TABLES FROM test LIKE 'replication_test';", quiet => 1 });

   if ($check3) {
      Rex::Logger::info("Table 'replication_test' exists on master");
   }
   else {
      Rex::Database::MySQL::Admin::execute({ sql => "CREATE TABLE test.replication_test (id INT AUTO_INCREMENT PRIMARY KEY, data varchar(20), ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP());" });

      my $check4 = Rex::Database::MySQL::Admin::execute({ sql => "SHOW TABLES FROM test LIKE 'replication_test';", quiet => 1 });

      if ($check4) {
         Rex::Logger::info("Created table 'replication_test' on master");
      }
      else {
         Rex::Logger::info("Failed to create table 'replication_test' on master", 'error');
         return 0;
      }
   }

   Rex::Database::MySQL::Admin::execute({ sql => "INSERT INTO test.replication_test (data) values ('$key');" });

   my $result = Rex::Database::MySQL::Admin::execute({ sql => "select id from test.replication_test where data = '$key' \\G", quiet => 1 });

   if ($result =~ /id: (\d+)/m) {

      Rex::Logger::info("Got id: $1 on master");

      # pass back the key so we can see if it arrives on the slaves
      return $key;
   }
   else {
      Rex::Logger::info("Failed to read id back from table 'replication_test' on master", 'error');
      return 0;
   }
};

task test_replication_slave => sub {

   my $params = shift;

   my $key = $params->{key};

   die "Need a key - giving up" unless $key;

   my $result = Rex::Database::MySQL::Admin::execute({ sql => "select id from test.replication_test where data = '$key' \\G", quiet => 1 });

   if ($result =~ /id: (\d+)/m) {

      Rex::Logger::info("Got id: $1 on slave");
      return 1;
   }
   else {
      Rex::Logger::info("Failed to read id back from table 'replication_test' on slave", 'error');
      return 0;
   }
};


task set_read_only => sub {

   my $params = shift;

   Rex::Logger::info("Setting server to read_only");

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

task register_master => sub {

   my $config = _load_config();

   my $master_host = connection->server()->{name};

   die 'Please specify target host' if $master_host eq '<local>'; # for now, no real reason why localhost can't be a master

   Rex::Logger::info("Registering replication master: $master_host");

   my $master = { host => $master_host };

   LOCAL {
      $master->{ip_addr}  = _ip_addr($master_host);
   };

   $master->{server_id} = Rex::Database::MySQL::Admin::get_variable('server_id');
   #$master->{log_bin} = Rex::Database::MySQL::Admin::get_variable('log_bin');

   if ($master->{server_id}) {

      Rex::Logger::info("Got existing server-id: $master->{server_id}");
   }
   else {
      die "No server-id set - not a master";
   }

   $config->{master} = $master;

   _save_config($config);
};

task register_slave => sub {

   my $config = _load_config();

   my $slave_host = connection->server()->{name};

   Rex::Logger::info("Registering replication slave: $slave_host");

   my $slave;

   my $existing = 0;

   foreach my $existing_slave (@{$config->{slaves}}) {

      if ($existing_slave->{host} eq $slave_host) {

         $slave = $existing_slave;
         $existing = 1;
         last;
      }
   }

   if ($existing) {
      Rex::Logger::info("Adding Slave $slave_host to config file");
   }
   else {
      Rex::Logger::info("Updating Slave $slave_host in config file");
   }

   $slave = { host => $slave_host } ;

   LOCAL {
      $slave->{ip_addr}  = _ip_addr($slave_host);
   };

   $slave->{server_id} = Rex::Database::MySQL::Admin::get_variable('server_id');

   $config->{slaves}->{$slave_host} = $slave;

   _save_config($config);
};

task unregister_slave => sub {

   my $slave_host = connection->server()->{name};

   my $config = _load_config();

   my $existing = 0;

   for (my $i = scalar @{$config->{slaves}}; $i > 0; $i--) {

      my $slave = $config->{slaves}->[$i];

      if ($slave->{host} eq $slave_host) {

         Rex::Logger::info("Removing Slave $slave_host from config file");

         $existing = 1;

         splice @{$config->{slaves}}, $i, 1;

         last;
      }
   }

   die "slave not found in config: $slave_host" unless $existing;

   _save_config($config);
};

sub _ip_addr {

   my $host = shift;

   my $result = run("resolveip $host");

   if ($result =~ /^IP address of $host is (\d+\.\d+\.\d+\.\d+)/) {

      return $1;
   }
   else {
      return undef;
   }
}

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

Rex::Database::MySQL::Admin::Replication - Manage MySQL Replication Master and Slave servers

=head1 USAGE

 set mysql => defaults_file => '/etc/mysql/debian.cnf';
 set mysql_replication => config_file => 'mysql_replication.cfg'; # only required if you want to change the default, which is 'replication.cfg'
 
 rex -H db-test-master Database:MySQL:Replication:init_master
 
 rex -H db-test-slave1 Database:MySQL:Replication:init_slave
 
 rex -H db-test-slave2 Database:MySQL:Replication:init_slave
 
 rex Database:MySQL:Replication:test_replication

(or to combine those last 3 lines in one command)

 rex -H 'db-test-slave db-test-slave2' Database:MySQL:Replication:init_slave test


=head1 TASKS

=over 4

=item set_read_only

This task will set the server to read_only mode.  Ideal for applying to master server before switching to a new master.

=item set_read_write

This task will remove the read_only setting.

=item init_master

This task will promote a mysql server to be a replication master.

=item demote_master

This task will demote a mysql server from being a replication master.

=item get_master_status

This task will return the master status.

=item get_slave_status

This task will return the slave status.

=item init_slaves

This task will initialise all slaves from the current master binlog position.  It grants necessary permissions, points each slave at the master, and starts replciation.

=item init_slave

This task initialises a single slave instance.

=item start_slave

Start replication on a single slave instance.

=item stop_slave

Stop replication on a single slave instance.

=item test_replication

Check all slaves are replicating corretly by inserting a row on the master and checking it propogates to all slaves.

=back

=cut


