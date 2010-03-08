use strict;
use lib ('/data/Lacuna-Server/lib');
use Plack::App::URLMap;
use Plack::App::Directory;
use Lacuna;

$|=1;

my $db = Lacuna::DB->new( access_key => $ENV{SIMPLEDB_ACCESS_KEY}, secret_key => $ENV{SIMPLEDB_SECRET_KEY}, cache_servers => [{host=>'127.0.0.1', port=>11211}]);

my $urlmap = Plack::App::URLMap->new;

open my $file, "<", "../var/index.html";
my @lines = <$file>;
close $file;
$urlmap->map("/" => sub { return [200, ['Content-Type' => 'text/html'], [join("\n",@lines)]]});

open my $file, "<", "../var/crossdomain.xml";
my @lines = <$file>;
close $file;
$urlmap->map("/crossdomain.xml" => sub { return [200, ['Content-Type' => 'text/xml'], [join("\n",@lines)]]});

$urlmap->map("/api/" => Plack::App::Directory->new({ root => "/data/api" })->to_app);

$urlmap->map("/map" => Lacuna::Map->new(simpledb=>$db)->to_app);
$urlmap->map("/body" => Lacuna::Body->new(simpledb=>$db)->to_app);
$urlmap->map("/empire" => Lacuna::Empire->new(simpledb=>$db)->to_app);
$urlmap->map("/inbox" => Lacuna::Inbox->new(simpledb=>$db)->to_app);
$urlmap->map("/species" => Lacuna::Species->new(simpledb=>$db)->to_app);

# buildings
$urlmap->map(Lacuna::Building::Algae->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Apple->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Bean->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Beeldeban->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Bread->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Burger->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Cheese->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Chip->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Cider->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Corn->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::CornMeal->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Crater->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Dairy->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Denton->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Development->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Embassy->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::EnergyReserve->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Entertainment->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Espionage->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Fission->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::FoodReserve->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Fusion->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::GasGiantLab->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::GasGiantPlatform->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Geo->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Hydrocarbon->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Intelligence->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Lapis->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Malcud->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Mine->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::MiningMinistry->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::MiningPlatform->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Network19->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Observatory->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::OreRefinery->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::OreStorage->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Pancake->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Park->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Pie->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::PlanetaryCommand->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Potato->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Propulsion->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::RND->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::RockyOutcrop->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Security->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Shake->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Shipyard->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Singularity->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Soup->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::SpacePort->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Syrup->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::TerraformingLab->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::TerraformingPlatform->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Trade->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Transporter->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::University->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::WasteEnergy->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::WasteRecycling->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::WasteSequestration->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::WasteTreatment->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::WaterProduction->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::WaterPurification->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::WaterReclamation->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::WaterStorage->new(simpledb=>$db)->to_app_with_url);
$urlmap->map(Lacuna::Building::Wheat->new(simpledb=>$db)->to_app_with_url);


$urlmap->to_app;


