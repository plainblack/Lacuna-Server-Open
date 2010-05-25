package Lacuna;

use strict;
use Module::Find qw(useall);
use Lacuna::DB;
use Config::JSON;

useall __PACKAGE__;

our $VERSION = 2.0100;

my $config = Config::JSON->new('/data/Lacuna-Server/etc/lacuna.conf');
my $db = Lacuna::DB->connect($config->get('db/dsn'),$config->get('db/username'),$config->get('db/password'));
my $cache = Lacuna::Cache->new(servers => $config->get('memcached'));

sub version {
    return $VERSION;
}

sub config {
    return $config;
}

sub db {
    return $db;
}

sub cache {
    return $cache;
}


1;
