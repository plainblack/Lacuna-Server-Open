use strict;
use lib ('/data/Lacuna-Server/lib');
use Config::JSON;
use Plack::App::URLMap;
use Plack::App::Directory;
use Log::Log4perl;
use Log::Any::Adapter;
use Lacuna;

$|=1;

my $config = Config::JSON->new("/data/Lacuna-Server/etc/lacuna.conf");

use Log::Log4perl;
Log::Log4perl::init('/data/Lacuna-Server/etc/log4perl.conf');
Log::Any::Adapter->set('Log::Log4perl');

my $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached'));

my $urlmap = Plack::App::URLMap->new;

#open my $file, "<", "../var/index.html";
#my @lines = <$file>;
#close $file;
#$urlmap->map("/" => sub { return [200, ['Content-Type' => 'text/html'], [join("\n",@lines)]]});

#open my $file, "<", "../var/local.html";
#my @lines = <$file>;
#close $file;
#$urlmap->map("/local" => sub { return [200, ['Content-Type' => 'text/html'], [join("\n",@lines)]]});

#open my $file, "<", "../var/crossdomain.xml";
#my @lines = <$file>;
#close $file;
#$urlmap->map("/crossdomain.xml" => sub { return [200, ['Content-Type' => 'text/xml'], [join("\n",@lines)]]});

#$urlmap->map("/api/" => Plack::App::Directory->new({ root => "/data/api" })->to_app);

$urlmap->map("/map" => Lacuna::Map->new->to_app);
$urlmap->map("/body" => Lacuna::Body->new->to_app);
$urlmap->map("/empire" => Lacuna::Empire->new->to_app);
$urlmap->map("/inbox" => Lacuna::Inbox->new->to_app);
$urlmap->map("/species" => Lacuna::Species->new->to_app);
$urlmap->map("/stats" => Lacuna::Stats->new->to_app);

# buildings
$urlmap->map(Lacuna::Building::Algae->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Apple->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Bean->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Beeldeban->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Bread->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Burger->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Cheese->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Chip->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Cider->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Corn->new->to_app_with_url);
$urlmap->map(Lacuna::Building::CornMeal->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Crater->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Dairy->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Denton->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Development->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Embassy->new->to_app_with_url);
$urlmap->map(Lacuna::Building::EnergyReserve->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Entertainment->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Espionage->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Fission->new->to_app_with_url);
$urlmap->map(Lacuna::Building::FoodReserve->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Fusion->new->to_app_with_url);
$urlmap->map(Lacuna::Building::GasGiantLab->new->to_app_with_url);
$urlmap->map(Lacuna::Building::GasGiantPlatform->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Geo->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Hydrocarbon->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Intelligence->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Lapis->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Malcud->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Mine->new->to_app_with_url);
$urlmap->map(Lacuna::Building::MiningMinistry->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Network19->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Observatory->new->to_app_with_url);
$urlmap->map(Lacuna::Building::OreRefinery->new->to_app_with_url);
$urlmap->map(Lacuna::Building::OreStorage->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Pancake->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Park->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Pie->new->to_app_with_url);
$urlmap->map(Lacuna::Building::PlanetaryCommand->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Potato->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Propulsion->new->to_app_with_url);
$urlmap->map(Lacuna::Building::RND->new->to_app_with_url);
$urlmap->map(Lacuna::Building::RockyOutcrop->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Security->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Shake->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Shipyard->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Singularity->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Soup->new->to_app_with_url);
$urlmap->map(Lacuna::Building::SpacePort->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Syrup->new->to_app_with_url);
$urlmap->map(Lacuna::Building::TerraformingLab->new->to_app_with_url);
$urlmap->map(Lacuna::Building::TerraformingPlatform->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Trade->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Transporter->new->to_app_with_url);
$urlmap->map(Lacuna::Building::University->new->to_app_with_url);
$urlmap->map(Lacuna::Building::WasteEnergy->new->to_app_with_url);
$urlmap->map(Lacuna::Building::WasteRecycling->new->to_app_with_url);
$urlmap->map(Lacuna::Building::WasteSequestration->new->to_app_with_url);
$urlmap->map(Lacuna::Building::WasteTreatment->new->to_app_with_url);
$urlmap->map(Lacuna::Building::WaterProduction->new->to_app_with_url);
$urlmap->map(Lacuna::Building::WaterPurification->new->to_app_with_url);
$urlmap->map(Lacuna::Building::WaterReclamation->new->to_app_with_url);
$urlmap->map(Lacuna::Building::WaterStorage->new->to_app_with_url);
$urlmap->map(Lacuna::Building::Wheat->new->to_app_with_url);


$urlmap->to_app;


