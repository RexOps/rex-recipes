
package Rex::Database::MySQL::Replication::ConfigStore;

use strict;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	show_config
	_load_config
	_load_master_config
	_load_slave_config
	_save_config
);

use Rex -base;

use Data::Dumper;


task show_config => sub {

	my $config = _load_config();

	say "CONFIG: " . Dumper($config);
};

sub _load_config {

	my $params = { @_ };

	my $config_file = $Rex::Database::MySQL::Admin::Replication::MYSQL_REPLICATION_CONF{config_file} || 'replication.cnf';;

	my $data;

	if (-e $config_file) {

		Rex::Logger::info("Loading config file: $config_file");

		$data = YAML::Tiny->read($config_file);

		$data = $data->[0] if $data;
	}

	$data->{master} = {} unless $data->{master};
	$data->{slaves} = {} unless $data->{master};

	#say "DATA: " . Dumper($data);

	return $data;
}

sub _save_config {

	my $data = shift;

	my $config_file = $Rex::Database::MySQL::Admin::Replication::MYSQL_REPLICATION_CONF{config_file} || 'replication.cnf';;

	my $config = YAML::Tiny->new;

	$config->[0] = $data;

	$config->write($config_file);

	Rex::Logger::info("Wrote config file: $config_file");
}

1;
