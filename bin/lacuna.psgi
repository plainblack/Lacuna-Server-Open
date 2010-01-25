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

open my $file, "<", "../var/index.html";
my @lines = <$file>;
close $file;
$urlmap->map("/" => sub { return [200, ['Content-Type' => 'text/html'], [join("\n",@lines)]]});

$urlmap->map("/api/" => Plack::App::Directory->new({ root => "/data/api" })->to_app);

$urlmap->map("/map" => Lacuna::Map->new(simpledb=>$db)->to_app);
$urlmap->map("/body" => Lacuna::Body->new(simpledb=>$db)->to_app);
$urlmap->map("/empire" => Lacuna::Empire->new(simpledb=>$db)->to_app);
$urlmap->map("/species" => Lacuna::Species->new(simpledb=>$db)->to_app);

$urlmap->to_app;


