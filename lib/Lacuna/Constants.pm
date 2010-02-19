package Lacuna::Constants;

use strict;
use base 'Exporter';

use constant INFLATION => 1.8847;
use constant GROWTH => 1.292;
use constant FOOD_TYPES => (qw(lapis potato apple root corn cider wheat bread soup chip pie pancake milk meal algae syrup fungus burger shake beetle));
use constant ORE_TYPES => (qw(rutile chromite chalcopyrite galena gold uraninite bauxite goethite halite gypsum trona kerogen methane anthracite sulfur zircon monazite fluorite beryl magnetite));
use constant BUILDABLE_CLASSES => (qw(
    Lacuna::Building::Algae
    Lacuna::Building::Apple
    Lacuna::Building::Bean
    Lacuna::Building::Beeldeban
    Lacuna::Building::Bread
    Lacuna::Building::Burger
    Lacuna::Building::Cheese
    Lacuna::Building::Chip
    Lacuna::Building::Cider
    Lacuna::Building::Corn
    Lacuna::Building::CornMeal
    Lacuna::Building::Dairy
    Lacuna::Building::Denton
    Lacuna::Building::Development
    Lacuna::Building::Embassy
    Lacuna::Building::EnergyReserve
    Lacuna::Building::Entertainment
    Lacuna::Building::Espionage
    Lacuna::Building::Fission
    Lacuna::Building::FoodReserve
    Lacuna::Building::Fusion
    Lacuna::Building::GasGiantLab
    Lacuna::Building::Geo
    Lacuna::Building::Hydrocarbon
    Lacuna::Building::Intelligence
    Lacuna::Building::Lapis
    Lacuna::Building::Malcud
    Lacuna::Building::Mine
    Lacuna::Building::MiningMinistry
    Lacuna::Building::Network19
    Lacuna::Building::Observatory
    Lacuna::Building::OreRefinery
    Lacuna::Building::OreStorage
    Lacuna::Building::Pancake
    Lacuna::Building::Park
    Lacuna::Building::Pie
    Lacuna::Building::Potato
    Lacuna::Building::Propulsion
    Lacuna::Building::RND
    Lacuna::Building::Security
    Lacuna::Building::Shake
    Lacuna::Building::Shipyard
    Lacuna::Building::Singularity
    Lacuna::Building::Soup
    Lacuna::Building::SpacePort
    Lacuna::Building::Syrup
    Lacuna::Building::TerraformingLab
    Lacuna::Building::Trade
    Lacuna::Building::Transporter
    Lacuna::Building::University
    Lacuna::Building::WasteEnergy
    Lacuna::Building::WasteRecycling
    Lacuna::Building::WasteSequestration
    Lacuna::Building::WasteTreatment
    Lacuna::Building::WaterProduction
    Lacuna::Building::WaterPurification
    Lacuna::Building::WaterReclamation
    Lacuna::Building::WaterStorage
    Lacuna::Building::Wheat
    ));

our @EXPORT_OK = qw(
    INFLATION
    GROWTH
    FOOD_TYPES
    ORE_TYPES
    BUILDABLE_CLASSES
);

our %EXPORT_TAGS = (
    all =>  [qw(
        INFLATION
        GROWTH
        FOOD_TYPES
        ORE_TYPES
        BUILDABLE_CLASSES
        )],
);

1;
