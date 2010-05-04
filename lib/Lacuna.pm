package Lacuna;

use strict;
use Module::Find qw(useall);
use Lacuna::DB;
use Config::JSON;

useall __PACKAGE__;

our $VERSION = 1.1000;

our $config = Config::JSON->new('/data/Lacuna-Server/etc/lacuna.conf');

sub version {
    return $VERSION;
}

sub config {
    return $config;
}

1;
