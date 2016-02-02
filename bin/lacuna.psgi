use strict;
use lib ('/data/Lacuna-Server/lib');
use 5.010;
use Config::JSON;
use Plack::App::URLMap;
use Log::Log4perl;
use Log::Any::Adapter;
use Lacuna;
use Plack::Builder;
use JSON qw(encode_json);


$|=1;

my $config = Config::JSON->new("/data/Lacuna-Server/etc/lacuna.conf");

use Log::Log4perl;
Log::Log4perl::init('/data/Lacuna-Server/etc/log4perl.conf');
Log::Any::Adapter->set('Log::Log4perl');

my $offline = [ 500,
    [ 'Content-Type' => 'application/json-rpc' ],
    [ encode_json( {
        "jsonrpc" => "2.0",
        "error" => {
            "code" => -32000,
            "message" => "The server is offline for maintenance.",
        }
    } ) ],
];

my $gameover = [ 500,
    [ 'Content-Type' => 'application/json-rpc' ],
    [ encode_json( {
        "jsonrpc" => "2.0",
        "error" => {
            "code" => 1200,
            "message" => "Game Over",
            "data" => "http://community.lacunaexanse.com/wiki/hall-of-fame",
        }
    } ) ],
];

my $app = builder {
    unless ($^O eq 'darwin') {
        ##Wrapper to fully enable size limiting.  The psgix.harakiri has to be set for it to work.
        enable sub {
            my $app = shift;
            return sub {
                my ($env) = @_;
                $env->{'psgix.harakiri'} = 1;
                return $app->($env);
            }
        };
        enable "Plack::Middleware::SizeLimit" => (
            max_unshared_size_in_kb => '51200', # 50MB
            # min_shared_size_in_kb => '8192', # 8MB
            max_process_size_in_kb => '125000', # 125MB
            check_every_n_requests => 3
        );
        enable "Plack::Middleware::LightProfile";
    }  
    enable 'CrossOrigin',
        origins => '*', methods => ['GET', 'POST'], max_age => 60*60*24*30, headers => '*';

    enable sub {
        my $app = shift;
        return sub {
            my ($env) = @_;
            my $status = Lacuna->cache->get('server','status');
            if ($status eq 'Offline') {
                return $offline;
            }
            elsif ($status eq 'Game Over') {
                return $gameover;
            }
            $app->($env);
        }
    };

    mount '/starman_ping' => sub { [200, [ 'Content-Type' => 'text/plain'], [ 'pong' ]] };

    mount "/map"            => Lacuna::RPC::Map->new->to_app;
    mount "/body"           => Lacuna::RPC::Body->new->to_app;
    mount "/empire"         => Lacuna::RPC::Empire->new->to_app;
    mount "/alliance"       => Lacuna::RPC::Alliance->new->to_app;
    mount "/inbox"          => Lacuna::RPC::Inbox->new->to_app;
    mount "/stats"          => Lacuna::RPC::Stats->new->to_app;
    mount "/pay"            => Lacuna::Web::Pay->new->to_app;
    mount "/chat"           => Lacuna::Web::Chat->new->to_app;
    mount "/chat/rpc"       => Lacuna::RPC::Chat->new->to_app;
    mount "/entertainment/vote" => Lacuna::Web::EntertainmentVote->new->to_app;
    mount "/announcement"   => Lacuna::Web::Announcement->new->to_app;
    mount "/facebook"       => Lacuna::Web::Facebook->new->to_app;
    mount "/apikey"         => Lacuna::Web::ApiKey->new->to_app;
    mount "/essentia-code"  => Lacuna::RPC::EssentiaCode->new->to_app;
    mount "/captcha"        => Lacuna::RPC::Captcha->new->to_app;

    for my $building (qw(
        Lacuna::RPC::Building::Shipyard
        Lacuna::RPC::Building::SpacePort
        Lacuna::RPC::Building::Intelligence
        Lacuna::RPC::Building::IntelTraining
        Lacuna::RPC::Building::MayhemTraining
        Lacuna::RPC::Building::PoliticsTraining
        Lacuna::RPC::Building::TheftTraining
        Lacuna::RPC::Building::Security
        Lacuna::RPC::Building::Trade
        Lacuna::RPC::Building::Transporter
        Lacuna::RPC::Building::Archaeology
        Lacuna::RPC::Building::DistributionCenter
        Lacuna::RPC::Building::SAW
        Lacuna::RPC::Building::AtmosphericEvaporator
        Lacuna::RPC::Building::GreatBallOfJunk
        Lacuna::RPC::Building::JunkHengeSculpture
        Lacuna::RPC::Building::MetalJunkArches
        Lacuna::RPC::Building::PyramidJunkSculpture
        Lacuna::RPC::Building::SpaceJunkPark
        Lacuna::RPC::Building::ThemePark
        Lacuna::RPC::Building::BlackHoleGenerator
        Lacuna::RPC::Building::TheDillonForge
        Lacuna::RPC::Building::HallsOfVrbansk
        Lacuna::RPC::Building::GratchsGauntlet
        Lacuna::RPC::Building::KasternsKeep
        Lacuna::RPC::Building::SubspaceSupplyDepot
        Lacuna::RPC::Building::SupplyPod
        Lacuna::RPC::Building::PantheonOfHagness
        Lacuna::RPC::Building::Capitol
        Lacuna::RPC::Building::Stockpile
        Lacuna::RPC::Building::Algae
        Lacuna::RPC::Building::Apple
        Lacuna::RPC::Building::Bean
        Lacuna::RPC::Building::Beeldeban
        Lacuna::RPC::Building::Bread
        Lacuna::RPC::Building::Burger
        Lacuna::RPC::Building::Cheese
        Lacuna::RPC::Building::Chip
        Lacuna::RPC::Building::Cider
        Lacuna::RPC::Building::Corn
        Lacuna::RPC::Building::CornMeal
        Lacuna::RPC::Building::EssentiaVein
        Lacuna::RPC::Building::Volcano
        Lacuna::RPC::Building::MassadsHenge
        Lacuna::RPC::Building::LibraryOfJith
        Lacuna::RPC::Building::NaturalSpring
        Lacuna::RPC::Building::OracleOfAnid
        Lacuna::RPC::Building::TempleOfTheDrajilites
        Lacuna::RPC::Building::GeoThermalVent
        Lacuna::RPC::Building::InterDimensionalRift
        Lacuna::RPC::Building::CitadelOfKnope
        Lacuna::RPC::Building::CrashedShipSite
        Lacuna::RPC::Building::KalavianRuins
        Lacuna::RPC::Building::Grove
        Lacuna::RPC::Building::Sand
        Lacuna::RPC::Building::Lagoon
        Lacuna::RPC::Building::Crater
        Lacuna::RPC::Building::Dairy
        Lacuna::RPC::Building::Denton
        Lacuna::RPC::Building::Development
        Lacuna::RPC::Building::Embassy
        Lacuna::RPC::Building::EnergyReserve
        Lacuna::RPC::Building::Entertainment
        Lacuna::RPC::Building::Espionage
        Lacuna::RPC::Building::Fission
        Lacuna::RPC::Building::FoodReserve
        Lacuna::RPC::Building::Fusion
        Lacuna::RPC::Building::DeployedBleeder
        Lacuna::RPC::Building::GasGiantLab
        Lacuna::RPC::Building::GasGiantPlatform
        Lacuna::RPC::Building::Geo
        Lacuna::RPC::Building::Hydrocarbon
        Lacuna::RPC::Building::Lapis
        Lacuna::RPC::Building::Malcud
        Lacuna::RPC::Building::Mine
        Lacuna::RPC::Building::MiningMinistry
        Lacuna::RPC::Building::Network19
        Lacuna::RPC::Building::Observatory
        Lacuna::RPC::Building::OreRefinery
        Lacuna::RPC::Building::OreStorage
        Lacuna::RPC::Building::Pancake
        Lacuna::RPC::Building::Park
        Lacuna::RPC::Building::Pie
        Lacuna::RPC::Building::PlanetaryCommand
        Lacuna::RPC::Building::Potato
        Lacuna::RPC::Building::Propulsion
        Lacuna::RPC::Building::Oversight
        Lacuna::RPC::Building::RockyOutcrop
        Lacuna::RPC::Building::Lake
        Lacuna::RPC::Building::Shake
        Lacuna::RPC::Building::Singularity
        Lacuna::RPC::Building::Soup
        Lacuna::RPC::Building::Syrup
        Lacuna::RPC::Building::TerraformingLab
        Lacuna::RPC::Building::GeneticsLab
        Lacuna::RPC::Building::TerraformingPlatform
        Lacuna::RPC::Building::University
        Lacuna::RPC::Building::WasteEnergy
        Lacuna::RPC::Building::WasteExchanger
        Lacuna::RPC::Building::WasteRecycling
        Lacuna::RPC::Building::WasteSequestration
        Lacuna::RPC::Building::WasteDigester
        Lacuna::RPC::Building::WasteTreatment
        Lacuna::RPC::Building::WaterProduction
        Lacuna::RPC::Building::WaterPurification
        Lacuna::RPC::Building::WaterReclamation
        Lacuna::RPC::Building::WaterStorage
        Lacuna::RPC::Building::Wheat
        Lacuna::RPC::Building::Beach1
        Lacuna::RPC::Building::Beach2
        Lacuna::RPC::Building::Beach3
        Lacuna::RPC::Building::Beach4
        Lacuna::RPC::Building::Beach5
        Lacuna::RPC::Building::Beach6
        Lacuna::RPC::Building::Beach7
        Lacuna::RPC::Building::Beach8
        Lacuna::RPC::Building::Beach9
        Lacuna::RPC::Building::Beach10
        Lacuna::RPC::Building::Beach11
        Lacuna::RPC::Building::Beach12
        Lacuna::RPC::Building::Beach13
        Lacuna::RPC::Building::PilotTraining
        Lacuna::RPC::Building::MissionCommand
        Lacuna::RPC::Building::CloakingLab
        Lacuna::RPC::Building::MunitionsLab
        Lacuna::RPC::Building::LuxuryHousing
        Lacuna::RPC::Building::Fissure
        Lacuna::RPC::Building::Ravine
        Lacuna::RPC::Building::AlgaePond
        Lacuna::RPC::Building::LapisForest
        Lacuna::RPC::Building::BeeldebanNest
        Lacuna::RPC::Building::MalcudField
        Lacuna::RPC::Building::SSLa
        Lacuna::RPC::Building::SSLb
        Lacuna::RPC::Building::SSLc
        Lacuna::RPC::Building::SSLd
        Lacuna::RPC::Building::AmalgusMeadow
        Lacuna::RPC::Building::DentonBrambles
        Lacuna::RPC::Building::MercenariesGuild
        Lacuna::RPC::Building::StationCommand
        Lacuna::RPC::Building::OperaHouse
        Lacuna::RPC::Building::ArtMuseum
        Lacuna::RPC::Building::CulinaryInstitute
        Lacuna::RPC::Building::IBS
        Lacuna::RPC::Building::Warehouse
        Lacuna::RPC::Building::Parliament
        Lacuna::RPC::Building::PoliceStation
        Lacuna::RPC::Building::LCOTa
        Lacuna::RPC::Building::LCOTb
        Lacuna::RPC::Building::LCOTc
        Lacuna::RPC::Building::LCOTd
        Lacuna::RPC::Building::LCOTe
        Lacuna::RPC::Building::LCOTf
        Lacuna::RPC::Building::LCOTg
        Lacuna::RPC::Building::LCOTh
        Lacuna::RPC::Building::LCOTi
    )) {
        mount $building->new->to_app_with_url;
    }

    mount '/admin' => builder {
        enable "Auth::Basic", authenticator => sub {
            my ($username, $password) = @_;
            return 0 unless $username;
            my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name => $username, is_admin => 1})->first;
            return 0 unless defined $empire;
            return $empire->is_password_valid($password);
        };
        Lacuna::Web::Admin->new->to_app;
    };

    mount "/missioncurator" => builder {
        enable "Auth::Basic", authenticator => sub {
            my ($username, $password) = @_;
            return 0 unless $username;
            my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name => $username, is_mission_curator => 1})->first;
            return 0 unless defined $empire;
            return $empire->is_password_valid($password);
        };
        Lacuna::Web::MissionCurator->new->to_app;
    };

};

say "Server Started";

$app;

