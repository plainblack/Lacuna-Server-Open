use strict;
use lib ('/data/Lacuna-Server-Open/lib');
use Data::Dumper;
use Lacuna::DB;
use Lacuna;
use Getopt::Long;

our $quiet;
our $db = Lacuna->db;
my $empire_id;
my $bid;
  GetOptions(
    'quiet'    => \$quiet,  
    'empire_id=s' => \$empire_id,
    'bid=s'   => \$bid,
  );

  my $empires = $db->resultset('Lacuna::DB::Result::Empire');
  my $empire = $empires->find($empire_id);
  die "Could not find Empire!\n" unless $empire;
  print "Setting up for empire: ".$empire->name." : ".$empire_id."\n";
  my $ehash;
  my $body;
  if ($bid) {
      $body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($bid);
  }
  else {
      $body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($empire->home_planet_id);
  }

print "Building, lvl, food_hour, ore_hour, water_hour, energy_hour, waste_hour, happiness_hour, food_capacity, ore_capacity, water_capacity, energy_capacity, waste_capacity, food cost, ore cost, water cost, energy cost, waste cost, time cost\n";

for my $building (qw(
    Lacuna::DB::Result::Building::Shipyard
    Lacuna::DB::Result::Building::SpacePort
    Lacuna::DB::Result::Building::Intelligence
    Lacuna::DB::Result::Building::IntelTraining
    Lacuna::DB::Result::Building::MayhemTraining
    Lacuna::DB::Result::Building::PoliticsTraining
    Lacuna::DB::Result::Building::TheftTraining
    Lacuna::DB::Result::Building::Security
    Lacuna::DB::Result::Building::Trade
    Lacuna::DB::Result::Building::Transporter
    Lacuna::DB::Result::Building::Archaeology
    Lacuna::DB::Result::Building::DistributionCenter
    Lacuna::DB::Result::Building::SAW
    Lacuna::DB::Result::Building::Water::AtmosphericEvaporator
    Lacuna::DB::Result::Building::Permanent::GreatBallOfJunk
    Lacuna::DB::Result::Building::Permanent::JunkHengeSculpture
    Lacuna::DB::Result::Building::Permanent::MetalJunkArches
    Lacuna::DB::Result::Building::Permanent::PyramidJunkSculpture
    Lacuna::DB::Result::Building::Permanent::SpaceJunkPark
    Lacuna::DB::Result::Building::ThemePark
    Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator
    Lacuna::DB::Result::Building::Permanent::TheDillonForge
    Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk
    Lacuna::DB::Result::Building::Permanent::GratchsGauntlet
    Lacuna::DB::Result::Building::Permanent::KasternsKeep
    Lacuna::DB::Result::Building::SubspaceSupplyDepot
    Lacuna::DB::Result::Building::SupplyPod
    Lacuna::DB::Result::Building::Permanent::PantheonOfHagness
    Lacuna::DB::Result::Building::Capitol
    Lacuna::DB::Result::Building::Stockpile
    Lacuna::DB::Result::Building::Food::Algae
    Lacuna::DB::Result::Building::Food::Apple
    Lacuna::DB::Result::Building::Food::Bean
    Lacuna::DB::Result::Building::Food::Beeldeban
    Lacuna::DB::Result::Building::Food::Bread
    Lacuna::DB::Result::Building::Food::Burger
    Lacuna::DB::Result::Building::Food::Cheese
    Lacuna::DB::Result::Building::Food::Chip
    Lacuna::DB::Result::Building::Food::Cider
    Lacuna::DB::Result::Building::Food::Corn
    Lacuna::DB::Result::Building::Food::CornMeal
    Lacuna::DB::Result::Building::Permanent::EssentiaVein
    Lacuna::DB::Result::Building::Permanent::Volcano
    Lacuna::DB::Result::Building::Permanent::MassadsHenge
    Lacuna::DB::Result::Building::Permanent::LibraryOfJith
    Lacuna::DB::Result::Building::Permanent::NaturalSpring
    Lacuna::DB::Result::Building::Permanent::OracleOfAnid
    Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites
    Lacuna::DB::Result::Building::Permanent::GeoThermalVent
    Lacuna::DB::Result::Building::Permanent::InterDimensionalRift
    Lacuna::DB::Result::Building::Permanent::CitadelOfKnope
    Lacuna::DB::Result::Building::Permanent::CrashedShipSite
    Lacuna::DB::Result::Building::Permanent::KalavianRuins
    Lacuna::DB::Result::Building::Permanent::Grove
    Lacuna::DB::Result::Building::Permanent::Sand
    Lacuna::DB::Result::Building::Permanent::Lagoon
    Lacuna::DB::Result::Building::Permanent::Crater
    Lacuna::DB::Result::Building::Food::Dairy
    Lacuna::DB::Result::Building::Permanent::DentonBrambles
    Lacuna::DB::Result::Building::Development
    Lacuna::DB::Result::Building::Embassy
    Lacuna::DB::Result::Building::Energy::Reserve
    Lacuna::DB::Result::Building::EntertainmentDistrict
    Lacuna::DB::Result::Building::Espionage
    Lacuna::DB::Result::Building::Energy::Fission
    Lacuna::DB::Result::Building::Food::Reserve
    Lacuna::DB::Result::Building::Energy::Fusion
    Lacuna::DB::Result::Building::DeployedBleeder
    Lacuna::DB::Result::Building::GasGiantLab
    Lacuna::DB::Result::Building::Permanent::GasGiantPlatform
    Lacuna::DB::Result::Building::Energy::Geo
    Lacuna::DB::Result::Building::Energy::Hydrocarbon
    Lacuna::DB::Result::Building::Food::Lapis
    Lacuna::DB::Result::Building::Food::Malcud
    Lacuna::DB::Result::Building::Ore::Mine
    Lacuna::DB::Result::Building::Ore::Ministry
    Lacuna::DB::Result::Building::Network19
    Lacuna::DB::Result::Building::Observatory
    Lacuna::DB::Result::Building::Ore::Refinery
    Lacuna::DB::Result::Building::Ore::Storage
    Lacuna::DB::Result::Building::Food::Pancake
    Lacuna::DB::Result::Building::Park
    Lacuna::DB::Result::Building::Food::Pie
    Lacuna::DB::Result::Building::PlanetaryCommand
    Lacuna::DB::Result::Building::Food::Potato
    Lacuna::DB::Result::Building::Propulsion
    Lacuna::DB::Result::Building::Oversight
    Lacuna::DB::Result::Building::Permanent::RockyOutcrop
    Lacuna::DB::Result::Building::Permanent::Lake
    Lacuna::DB::Result::Building::Food::Shake
    Lacuna::DB::Result::Building::Energy::Singularity
    Lacuna::DB::Result::Building::Food::Soup
    Lacuna::DB::Result::Building::Food::Syrup
    Lacuna::DB::Result::Building::TerraformingLab
    Lacuna::DB::Result::Building::GeneticsLab
    Lacuna::DB::Result::Building::Permanent::TerraformingPlatform
    Lacuna::DB::Result::Building::University
    Lacuna::DB::Result::Building::Energy::Waste
    Lacuna::DB::Result::Building::Waste::Exchanger
    Lacuna::DB::Result::Building::Waste::Recycling
    Lacuna::DB::Result::Building::Waste::Sequestration
    Lacuna::DB::Result::Building::Waste::Digester
    Lacuna::DB::Result::Building::Waste::Treatment
    Lacuna::DB::Result::Building::Water::Production
    Lacuna::DB::Result::Building::Water::Purification
    Lacuna::DB::Result::Building::Water::Reclamation
    Lacuna::DB::Result::Building::Water::Storage
    Lacuna::DB::Result::Building::Food::Wheat
    Lacuna::DB::Result::Building::Permanent::Beach1
    Lacuna::DB::Result::Building::Permanent::Beach2
    Lacuna::DB::Result::Building::Permanent::Beach3
    Lacuna::DB::Result::Building::Permanent::Beach4
    Lacuna::DB::Result::Building::Permanent::Beach5
    Lacuna::DB::Result::Building::Permanent::Beach6
    Lacuna::DB::Result::Building::Permanent::Beach7
    Lacuna::DB::Result::Building::Permanent::Beach8
    Lacuna::DB::Result::Building::Permanent::Beach9
    Lacuna::DB::Result::Building::Permanent::Beach10
    Lacuna::DB::Result::Building::Permanent::Beach11
    Lacuna::DB::Result::Building::Permanent::Beach12
    Lacuna::DB::Result::Building::Permanent::Beach13
    Lacuna::DB::Result::Building::PilotTraining
    Lacuna::DB::Result::Building::MissionCommand
    Lacuna::DB::Result::Building::CloakingLab
    Lacuna::DB::Result::Building::MunitionsLab
    Lacuna::DB::Result::Building::LuxuryHousing
    Lacuna::DB::Result::Building::Permanent::Fissure
    Lacuna::DB::Result::Building::Permanent::Ravine
    Lacuna::DB::Result::Building::Permanent::AlgaePond
    Lacuna::DB::Result::Building::Permanent::LapisForest
    Lacuna::DB::Result::Building::Permanent::BeeldebanNest
    Lacuna::DB::Result::Building::Permanent::MalcudField
    Lacuna::DB::Result::Building::SSLa
    Lacuna::DB::Result::Building::SSLb
    Lacuna::DB::Result::Building::SSLc
    Lacuna::DB::Result::Building::SSLd
    Lacuna::DB::Result::Building::Permanent::AmalgusMeadow
    Lacuna::DB::Result::Building::Permanent::DentonBrambles
    Lacuna::DB::Result::Building::MercenariesGuild
    Lacuna::DB::Result::Building::Module::StationCommand
    Lacuna::DB::Result::Building::Module::OperaHouse
    Lacuna::DB::Result::Building::Module::ArtMuseum
    Lacuna::DB::Result::Building::Module::CulinaryInstitute
    Lacuna::DB::Result::Building::Module::IBS
    Lacuna::DB::Result::Building::Module::Warehouse
    Lacuna::DB::Result::Building::Module::Parliament
    Lacuna::DB::Result::Building::Module::PoliceStation
    Lacuna::DB::Result::Building::LCOTa
    Lacuna::DB::Result::Building::LCOTb
    Lacuna::DB::Result::Building::LCOTc
    Lacuna::DB::Result::Building::LCOTd
    Lacuna::DB::Result::Building::LCOTe
    Lacuna::DB::Result::Building::LCOTf
    Lacuna::DB::Result::Building::LCOTg
    Lacuna::DB::Result::Building::LCOTh
    Lacuna::DB::Result::Building::LCOTi
    )) {
    my $lvl = 1;
    for my $lvl (1..30) {
      my $obj = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
          body_id  => $bid,
          class    => $building,
          level    => $lvl,
          body     => $body,
        });
      my $cost = $obj->cost_to_upgrade;
      print join(",", $obj->name, $lvl,
                      $obj->food_hour,
                      $obj->ore_hour,
                      $obj->water_hour,
                      $obj->energy_hour,
                      $obj->waste_hour,
                      $obj->happiness_hour,
                      $obj->food_capacity,
                      $obj->ore_capacity,
                      $obj->water_capacity,
                      $obj->energy_capacity,
                      $obj->waste_capacity,
                      $cost->{food},
                      $cost->{ore},
                      $cost->{water},
                      $cost->{energy},
                      $cost->{waste},
                      $cost->{time},
                ),"\n";
     }

}
