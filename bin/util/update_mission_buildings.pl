use strict;
use 5.010;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna;
use Config::JSON;
use Module::Find;

$|=1;


my %buildings = map { $_ => $_->name } findallmod Lacuna::DB::Result::Building;
my $config = Config::JSON->create('/data/Lacuna-Mission/var/resources.conf');
$config->set('buildings', \%buildings);

