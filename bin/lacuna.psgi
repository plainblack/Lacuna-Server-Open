use strict;
use lib ('/data/Lacuna-Server/lib');
use Config::JSON;
use Plack::App::URLMap;
use Plack::App::Directory;
use Log::Log4perl;
use Log::Any::Adapter;
use Lacuna;
use Plack::Builder;
use Digest::SHA;


$|=1;

my $config = Config::JSON->new("/data/Lacuna-Server/etc/lacuna.conf");

use Log::Log4perl;
Log::Log4perl::init('/data/Lacuna-Server/etc/log4perl.conf');
Log::Any::Adapter->set('Log::Log4perl');

my $urlmap = Plack::App::URLMap->new;

$urlmap->map("/map" => Lacuna::RPC::Map->new->to_app);
$urlmap->map("/body" => Lacuna::RPC::Body->new->to_app);
$urlmap->map("/empire" => Lacuna::RPC::Empire->new->to_app);
$urlmap->map("/inbox" => Lacuna::RPC::Inbox->new->to_app);
$urlmap->map("/species" => Lacuna::RPC::Species->new->to_app);
$urlmap->map("/stats" => Lacuna::RPC::Stats->new->to_app);
$urlmap->map("/pay" => Lacuna::Web::Pay->new->to_app);
$urlmap->map("/facebook" => Lacuna::Web::Facebook->new->to_app);
$urlmap->map("/apikey" => Lacuna::Web::ApiKey->new->to_app);

# buildings
$urlmap->map(Lacuna::RPC::Building::Algae->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Apple->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Bean->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beeldeban->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Bread->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Burger->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Cheese->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Chip->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Cider->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Corn->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::CornMeal->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::EssentiaVein->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Volcano->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::MassadsHenge->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::LibraryOfJith->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::NaturalSpring->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::OracleOfAnid->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::TempleOfTheDrajilites->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::GeoThermalVent->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::InterDimensionalRift->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::KalavianRuins->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Crater->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Dairy->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Denton->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Development->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Embassy->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::EnergyReserve->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Entertainment->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Espionage->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Fission->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::FoodReserve->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Fusion->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::GasGiantLab->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::GasGiantPlatform->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Geo->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Hydrocarbon->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Intelligence->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Lapis->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Malcud->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Mine->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::MiningMinistry->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Network19->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Observatory->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::OreRefinery->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::OreStorage->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Pancake->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Park->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Pie->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::PlanetaryCommand->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Potato->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Propulsion->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Oversight->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::RockyOutcrop->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Lake->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Security->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Shake->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Shipyard->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Singularity->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Soup->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::SpacePort->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Syrup->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::TerraformingLab->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::GeneticsLab->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Archaeology->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::TerraformingPlatform->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Trade->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Transporter->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::University->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::WasteEnergy->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::WasteRecycling->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::WasteSequestration->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::WasteDigester->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::WasteTreatment->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::WaterProduction->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::WaterPurification->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::WaterReclamation->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::WaterStorage->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Wheat->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach1->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach2->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach3->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach4->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach5->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach6->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach7->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach8->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach9->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach10->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach11->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach12->new->to_app_with_url);
$urlmap->map(Lacuna::RPC::Building::Beach13->new->to_app_with_url);

# admin
my $admin = builder {
    enable "Auth::Basic", authenticator => sub {
        my ($username, $password) = @_;
        return 0 unless $username;
        my $admins = Lacuna->config->get('admins');
        return $admins->{$username} eq Digest::SHA::sha256_base64($password);
    };
    Lacuna::Web::Admin->new->to_app;
};
$urlmap->map("/admin" => $admin);



$urlmap->to_app;


