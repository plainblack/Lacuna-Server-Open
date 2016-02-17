use lib '../lib';
use Test::More tests => 6;
use Test::Deep;
use Data::Dumper;
use 5.010;
use Config::JSON;


use_ok('Lacuna::Cache');

my $config = Config::JSON->new('/data/Lacuna-Server-Open/etc/reboot.conf');
my $cache = Lacuna::Cache->new(servers => $config->get('memcached'));

$cache->set('foo','bar',3);
is($cache->get('foo','bar'), 3, 'get/set works');

$cache->delete('foo','bar');
is($cache->get('foo','bar'), undef, 'delete works');

is($cache->increment('foo','bar'), 1, 'init incrementor');
is($cache->increment('foo','bar'), 2, 'increment initialized incrementor seems to work');
is($cache->get('foo','bar'), 2, 'increment works');



END {
}
