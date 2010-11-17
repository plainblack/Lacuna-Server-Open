package Lacuna::Constants;

use strict;
use base 'Exporter';

use constant INFLATION => 1.75;
use constant GROWTH => 1.55;
use constant FOOD_TYPES => (qw(cheese bean lapis potato apple root corn cider wheat bread soup chip pie pancake milk meal algae syrup fungus burger shake beetle));
use constant ORE_TYPES => (qw(rutile chromite chalcopyrite galena gold uraninite bauxite goethite halite gypsum trona kerogen methane anthracite sulfur zircon monazite fluorite beryl magnetite));
use constant FINDABLE_PLANS => (qw(
    Lacuna::DB::Result::Building::Permanent::Lagoon
    Lacuna::DB::Result::Building::Permanent::Sand
    Lacuna::DB::Result::Building::Permanent::Grove
    Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites
    Lacuna::DB::Result::Building::Permanent::PantheonOfHagness
    Lacuna::DB::Result::Building::Permanent::CitadelOfKnope
    Lacuna::DB::Result::Building::Permanent::CrashedShipSite
    Lacuna::DB::Result::Building::Permanent::InterDimensionalRift
    Lacuna::DB::Result::Building::Permanent::KalavianRuins
    Lacuna::DB::Result::Building::Permanent::NaturalSpring
    Lacuna::DB::Result::Building::Permanent::Volcano
    Lacuna::DB::Result::Building::Permanent::GeoThermalVent
    Lacuna::DB::Result::Building::Permanent::BeeldebanNest
    Lacuna::DB::Result::Building::Permanent::LapisForest
    Lacuna::DB::Result::Building::Permanent::MalcudField
    Lacuna::DB::Result::Building::Permanent::Ravine
    Lacuna::DB::Result::Building::Permanent::AlgaePond
    ));
use constant BUILDABLE_CLASSES => (qw(
    Lacuna::RPC::Building::MissionCommand
    Lacuna::RPC::Building::CloakingLab
    Lacuna::RPC::Building::MunitionsLab
    Lacuna::RPC::Building::LuxuryHousing
    Lacuna::RPC::Building::PilotTraining
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
    Lacuna::RPC::Building::GasGiantLab
    Lacuna::RPC::Building::Geo
    Lacuna::RPC::Building::Hydrocarbon
    Lacuna::RPC::Building::Intelligence
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
    Lacuna::RPC::Building::Potato
    Lacuna::RPC::Building::Propulsion
    Lacuna::RPC::Building::Oversight
    Lacuna::RPC::Building::Security
    Lacuna::RPC::Building::Shake
    Lacuna::RPC::Building::Shipyard
    Lacuna::RPC::Building::Singularity
    Lacuna::RPC::Building::Soup
    Lacuna::RPC::Building::SpacePort
    Lacuna::RPC::Building::Syrup
    Lacuna::RPC::Building::TerraformingLab
    Lacuna::RPC::Building::GeneticsLab
    Lacuna::RPC::Building::Archaeology
    Lacuna::RPC::Building::Trade
    Lacuna::RPC::Building::Transporter
    Lacuna::RPC::Building::University
    Lacuna::RPC::Building::WasteEnergy
    Lacuna::RPC::Building::WasteRecycling
    Lacuna::RPC::Building::WasteSequestration
    Lacuna::RPC::Building::WasteDigester
    Lacuna::RPC::Building::WasteTreatment
    Lacuna::RPC::Building::WaterProduction
    Lacuna::RPC::Building::WaterPurification
    Lacuna::RPC::Building::WaterReclamation
    Lacuna::RPC::Building::WaterStorage
    Lacuna::RPC::Building::Wheat
    ));

use constant SHIP_TYPES => (qw( probe short_range_colony_ship colony_ship spy_pod cargo_ship space_station 
                             smuggler_ship mining_platform_ship terraforming_platform_ship 
                             gas_giant_settlement_ship scow dory freighter snark 
                             drone fighter spy_shuttle observatory_seeker security_ministry_seeker 
                             spaceport_seeker excavator detonator scanner ));


our @EXPORT_OK = qw(
    INFLATION
    GROWTH
    FOOD_TYPES
    ORE_TYPES
    BUILDABLE_CLASSES
    SHIP_TYPES
    FINDABLE_PLANS
);

our %EXPORT_TAGS = (
    all =>  [qw(
        INFLATION
        GROWTH
        FOOD_TYPES
        ORE_TYPES
        BUILDABLE_CLASSES
        SHIP_TYPES
        FINDABLE_PLANS
        )],
);

1;
