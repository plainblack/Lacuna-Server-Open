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

use constant MEDALS => {
    P1                  => 'Settled P1 Type Planet',  
    P2                  => 'Settled P2 Type Planet',  
    P3                  => 'Settled P3 Type Planet',  
    P4                  => 'Settled P4 Type Planet',  
    P5                  => 'Settled P5 Type Planet',  
    P6                  => 'Settled P6 Type Planet',  
    P7                  => 'Settled P7 Type Planet',  
    P8                  => 'Settled P8 Type Planet',  
    P9                  => 'Settled P9 Type Planet',  
    P10                 => 'Settled P10 Type Planet',  
    P11                 => 'Settled P11 Type Planet',  
    P12                 => 'Settled P12 Type Planet',  
    P13                 => 'Settled P13 Type Planet',  
    P14                 => 'Settled P14 Type Planet',  
    P15                 => 'Settled P15 Type Planet',  
    P16                 => 'Settled P16 Type Planet',  
    P17                 => 'Settled P17 Type Planet',  
    P18                 => 'Settled P18 Type Planet',  
    P19                 => 'Settled P19 Type Planet',  
    P20                 => 'Settled P20 Type Planet',  
    G1                  => 'Settled G1 Type Gas Giant',  
    G2                  => 'Settled G2 Type Gas Giant',  
    G3                  => 'Settled G3 Type Gas Giant',  
    G4                  => 'Settled G4 Type Gas Giant',  
    G5                  => 'Settled G5 Type Gas Giant',  
    A1                  => 'Mined A1 Type Asteroid',
    A2                  => 'Mined A2 Type Asteroid',
    A3                  => 'Mined A3 Type Asteroid',
    A4                  => 'Mined A4 Type Asteroid',
    A5                  => 'Mined A5 Type Asteroid',
    building1           => 'Built a Level 1 Building',
    building2           => 'Built a Level 2 Building',
    building3           => 'Built a Level 3 Building',
    building4           => 'Built a Level 4 Building',
    building5           => 'Built a Level 5 Building',
    building6           => 'Built a Level 6 Building',
    building7           => 'Built a Level 7 Building',
    building8           => 'Built a Level 8 Building',
    building9           => 'Built a Level 9 Building',
    building10          => 'Built a Level 10 Building',
    building11          => 'Built a Level 11 Building',
    building12          => 'Built a Level 12 Building',
    building13          => 'Built a Level 13 Building',
    building14          => 'Built a Level 14 Building',
    building15          => 'Built a Level 15 Building',
    building16          => 'Built a Level 16 Building',
    building17          => 'Built a Level 17 Building',
    building18          => 'Built a Level 18 Building',
    building19          => 'Built a Level 19 Building',
    building20          => 'Built a Level 20 Building',
    building21          => 'Built a Level 21 Building',
    building22          => 'Built a Level 22 Building',
    building23          => 'Built a Level 23 Building',
    building24          => 'Built a Level 24 Building',
    building25          => 'Built a Level 25 Building',
    building26          => 'Built a Level 26 Building',
    building27          => 'Built a Level 27 Building',
    building28          => 'Built a Level 28 Building',
    building29          => 'Built a Level 29 Building',
    building30          => 'Built a Level 30 Building',
    Algae               => 'Build an Algae Cropper',
    Apple               => 'Built an Apple Orchard',
    Bean                => 'Built a Bean Plantation',
    Beeldeban           => 'Built a Beeldeban Herder',
    Bread               => 'Built a Bakery',
    Burger              => 'Build a Burger Factory',
    Cheese              => 'Build a Cheese Factory',
    Chip                => 'Built a Chip Frier',
    Cider               => 'Built a Cider Bottler',
    Corn                => 'Built a Corn Plantation',
    CornMeal            => 'Built a Corn Meal Grinder',
    Dairy               => 'Built a Dairy Farm',
    Denton              => 'Built a Denton Root Farm',
    Development         => 'Built a Development Ministry',
    Embassy             => 'Built an Embassy',
    EnergyReserve       => 'Built an Energy Reserve',
    Entertainment       => 'Built an Entertainment District',
    Espionage           => 'Built an Espionage Ministry',
    Fission             => 'Built a Fission Reactor',
    FoodReserve         => 'Built a Food Reserve',
    Fusion              => 'Built a Fusion Reactor',
    GasGiantLab         => 'Built a Gas Giant Lab',
    GasGiantPlatform    => 'Built a Gas Giant Platform',
    Geo                 => 'Built a Geo Energy Plant',
    Hydrocarbon         => 'Built a Hydrocarbon Energy Plant',
    Intelligence        => 'Built an Intelligence Ministry',
    Lapis               => 'Built a Lapis Orchard',
    Malcud              => 'Built a Malcud Fungus Farm',
    Mine                => 'Built a Mine',
    MiningMinistry      => 'Built a Mining Ministry',
    MiningPlatform      => 'Built a Mining Platform',
    Network19           => 'Built a Network 19 Affiliate',
    Observatory         => 'Built an Observatory',
    OreRefinery         => 'Built an Ore Refinery',
    OreStorage          => 'Built an Ore Storage Tank',
    Pancake             => 'Built a Pancake Factory',
    Park                => 'Built a Park',
    Pie                 => 'Built a Pie Factory',
    PlanetaryCommand    => 'Built a Planetary Command Center',
    Potato              => 'Built a Potato Plantation',
    Propulsion          => 'Built a Propulsion Factory',
    RND                 => 'Built a Research and Development Ministry',
    Security            => 'Built a Security Ministry',
    Shake               => 'Built a Shake Factory',
    Shipyard            => 'Built a Shipyard',
    Singularity         => 'Built a Singularity Energy Plant',
    Soup                => 'Built a Soup Cannery',
    SpacePort           => 'Built a Space Port',
    Syrup               => 'Built a Syrup Bottler',
    TerraformingLab     => 'Built a Terraforming Lab',
    TerraformingPlatform=> 'Built a Terraforming Platform',
    Trade               => 'Built a Trade Ministry',
    Transporter         => 'Built a Subspace Transporter',
    University          => 'Built a University',
    WasteEnergy         => 'Built a Waste Energy Plant',
    WasteRecycling      => 'Built a Waste Recycling Center',
    WasteSequestration  => 'Built a Waste Sequestration Well', 
    WasteTreatment      => 'Built a Waste Treatment Center',
    WaterProduction     => 'Built a Water Production Plant',
    WaterPurification   => 'Built a Water Purification Plant',
    WaterReclamation    => 'Built a Water Reclamation Plant',
    WaterStorage        => 'Built a Water Storage Tank',
    Wheat               => 'Built a Wheat Farm',
};

our @EXPORT_OK = qw(
    INFLATION
    GROWTH
    FOOD_TYPES
    ORE_TYPES
    BUILDABLE_CLASSES
    MEDALS
);

our %EXPORT_TAGS = (
    all =>  [qw(
        INFLATION
        GROWTH
        FOOD_TYPES
        ORE_TYPES
        BUILDABLE_CLASSES
        MEDALS
        )],
);

1;
