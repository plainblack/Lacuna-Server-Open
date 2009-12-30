use strict;
use lib ('../lib');
use Plack::App::URLMap;
use Plack::App::Directory;
use Lacuna::DB;
use Lacuna::Map;
use Lacuna::Species;
use Lacuna::Empire;

$|=1;

my $db = Lacuna::DB->new( access_key => $ENV{SIMPLEDB_ACCESS_KEY}, secret_key => $ENV{SIMPLEDB_SECRET_KEY}, cache_servers => [{host=>'127.0.0.1', port=>11211}]);

my $urlmap = Plack::App::URLMap->new;

$urlmap->map("/" => sub { return [200, ['Content-Type' => 'text/html'], [q{<html><head><title>The Lacuna Expanse</title></head><body><h1>The Lacuna Expanse</h1>You appear to be snooping around where you're not wanted.</body></html>}]]});
$urlmap->map("/api/" => Plack::App::Directory->new({ root => "/data/api" })->to_app);

$urlmap->map("/map" => Lacuna::Map->new(simpledb=>$db)->to_app);
$urlmap->map("/empire" => Lacuna::Empire->new(simpledb=>$db)->to_app);
$urlmap->map("/species" => Lacuna::Species->new(simpledb=>$db)->to_app);

$urlmap->to_app;

#Lacuna::Map->new(simpledb=>$db)->to_app

