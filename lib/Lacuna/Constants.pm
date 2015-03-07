package Lacuna::Constants;

use strict;
use base 'Exporter';

use constant INFLATION => 1.75;
use constant SECONDS_IN_A_DAY => 60 * 60 * 24;
use constant GROWTH => 1.55;
use constant MINIMUM_EXERTABLE_INFLUENCE => 10;
use constant FOOD_TYPES => (qw(cheese bean lapis potato apple root corn cider wheat bread soup chip pie pancake milk meal algae syrup fungus burger shake beetle));
use constant ORE_TYPES => (qw(rutile chromite chalcopyrite galena gold uraninite bauxite goethite halite gypsum trona kerogen methane anthracite sulfur zircon monazite fluorite beryl magnetite));
use constant BUILDABLE_CLASSES => (qw(
    Lacuna::RPC::Building::SSLa
    Lacuna::RPC::Building::SSLb
    Lacuna::RPC::Building::SSLc
    Lacuna::RPC::Building::SSLd
    Lacuna::RPC::Building::DistributionCenter
    Lacuna::RPC::Building::AtmosphericEvaporator
    Lacuna::RPC::Building::MetalJunkArches
    Lacuna::RPC::Building::SpaceJunkPark
    Lacuna::RPC::Building::SAW
    Lacuna::RPC::Building::PyramidJunkSculpture
    Lacuna::RPC::Building::JunkHengeSculpture
    Lacuna::RPC::Building::GreatBallOfJunk
    Lacuna::RPC::Building::ThemePark
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
    Lacuna::RPC::Building::IntelTraining
    Lacuna::RPC::Building::Lapis
    Lacuna::RPC::Building::Malcud
    Lacuna::RPC::Building::MayhemTraining
    Lacuna::RPC::Building::MercenariesGuild
    Lacuna::RPC::Building::Mine
    Lacuna::RPC::Building::MiningMinistry
    Lacuna::RPC::Building::Network19
    Lacuna::RPC::Building::Observatory
    Lacuna::RPC::Building::OreRefinery
    Lacuna::RPC::Building::OreStorage
    Lacuna::RPC::Building::Pancake
    Lacuna::RPC::Building::Park
    Lacuna::RPC::Building::Pie
    Lacuna::RPC::Building::PoliticsTraining
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
    Lacuna::RPC::Building::TheftTraining
    Lacuna::RPC::Building::GeneticsLab
    Lacuna::RPC::Building::Archaeology
    Lacuna::RPC::Building::Trade
    Lacuna::RPC::Building::Transporter
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
    ));
use constant SPACE_STATION_MODULES => (qw(
    Lacuna::RPC::Building::ArtMuseum
    Lacuna::RPC::Building::CulinaryInstitute
    Lacuna::RPC::Building::IBS
    Lacuna::RPC::Building::OperaHouse
    Lacuna::RPC::Building::Parliament
    Lacuna::RPC::Building::PoliceStation
    Lacuna::RPC::Building::StationCommand
    Lacuna::RPC::Building::Warehouse
    ));
use constant SHIP_TYPES => (qw( probe short_range_colony_ship colony_ship spy_pod cargo_ship space_station 
                             smuggler_ship mining_platform_ship terraforming_platform_ship surveyor
                             gas_giant_settlement_ship scow scow_fast scow_large scow_mega dory freighter snark snark2 snark3 thud
                             supply_pod supply_pod2 supply_pod3 supply_pod4 supply_pod5
                             drone fighter spy_shuttle observatory_seeker security_ministry_seeker 
                             spaceport_seeker excavator detonator scanner barge hulk hulk_fast hulk_huge galleon stake
                             placebo placebo2 placebo3 placebo4 placebo5 placebo6 bleeder sweeper fissure_sealer
                             ));
use constant SHIP_TRADE_TYPES => (qw(
    cargo_ship smuggler_ship freighter dory barge galleon hulk hulk_huge hulk_fast
));
use constant SHIP_WASTE_TYPES => (qw(
    scow scow_fast scow_large scow_mega
));
use constant SHIP_SINGLE_USE_TYPES => (qw( probe short_range_colony_ship colony_ship spy_pod space_station 
                                        mining_platform_ship terraforming_platform_ship surveyor
                                        gas_giant_settlement_ship snark snark2 snark3 thud
                                        supply_pod supply_pod2 supply_pod3 supply_pod4 supply_pod5
                                        drone spy_shuttle observatory_seeker security_ministry_seeker 
                                        spaceport_seeker excavator detonator scanner stake
                                        placebo placebo2 placebo3 placebo4 placebo5 placebo6 bleeder fissure_sealer
                                        ));
our @EXPORT_OK = qw(
    INFLATION
    SECONDS_IN_A_DAY
    GROWTH
    MINIMUM_EXERTABLE_INFLUENCE
    FOOD_TYPES
    ORE_TYPES
    BUILDABLE_CLASSES
    SPACE_STATION_MODULES
    SHIP_TYPES
    SHIP_TRADE_TYPES
    SHIP_WASTE_TYPES
    SHIP_SINGLE_USE_TYPES
);

our %EXPORT_TAGS = (
    all =>  [qw(
        INFLATION
        SECONDS_IN_A_DAY
        GROWTH
        MINIMUM_EXERTABLE_INFLUENCE
        FOOD_TYPES
        ORE_TYPES
        BUILDABLE_CLASSES
        SPACE_STATION_MODULES
        SHIP_TYPES
        SHIP_TRADE_TYPES
        SHIP_WASTE_TYPES
        SHIP_SINGLE_USE_TYPES
        )],
);

1;
