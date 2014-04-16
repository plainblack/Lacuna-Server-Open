package Lacuna;

use strict;
use Module::Find qw(useall);
use Lacuna::DB;
use Config::JSON;

useall __PACKAGE__;

our $VERSION = 3.0903;

my $config = Config::JSON->new('/home/icydee/Lacuna-Server-Open/lacuna.conf');
my $db = Lacuna::DB->connect($config->get('db/dsn'),$config->get('db/username'),$config->get('db/password'), { mysql_enable_utf8 => 1});

sub version {
    return $VERSION;
}

sub config {
    return $config;
}

sub db {
    return $db;
}

1;
