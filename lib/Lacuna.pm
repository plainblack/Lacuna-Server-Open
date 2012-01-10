package Lacuna;

use strict;
use Module::Find qw(useall);
use Lacuna::DB;
use Config::JSON;

useall __PACKAGE__;

our $VERSION = 3.0835;

my $config = Config::JSON->new('/data/Lacuna-Server/etc/lacuna.conf');
my $db = Lacuna::DB->connect($config->get('db/dsn'),$config->get('db/username'),$config->get('db/password'), { mysql_enable_utf8 => 1});
my $cache = Lacuna::Cache->new(servers => $config->get('memcached'));

#use IO::File;
# $db->storage->debug(1);
# $db->storage->debugfh(IO::File->new('/tmp/dbic.trace.out', 'w'));


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
