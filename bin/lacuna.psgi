use strict;
use lib ('../lib','/data/JSON-RPC-Dispatcher/lib');
use Lacuna::Map;
use Lacuna::DB;

my $db = Lacuna::DB->new( access_key => $ENV{SIMPLEDB_ACCESS_KEY}, secret_key => $ENV{SIMPLEDB_SECRET_KEY}, cache_servers => [{host=>'127.0.0.1', port=>11211}]);

Lacuna::Map->new(simpledb=>$db)->to_app;


