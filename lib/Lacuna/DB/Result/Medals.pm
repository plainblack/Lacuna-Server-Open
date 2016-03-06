package Lacuna::DB::Result::Medals;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('medals');
__PACKAGE__->add_columns(
    type                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    empire_id               => { data_type => 'int', size => 11, is_nullable => 0 },
    public                  => { data_type => 'bit', default_value => 1 },
    datestamp               => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    times_earned            => { data_type => 'int', size => 11, default_value => 1 },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');

sub format_datestamp {
    my ($self) = @_;
    return format_date($self->datestamp);
}

use constant MEDALS => {
    supply_pod => {
        name => 'Built Supply Pod',
        image => 'v2/supply_pod',
    },
    supply_pod2 => {
        name => 'Built Supply Pod II',
        image => 'v2/supply_pod2',
    },
    supply_pod3 => {
        name => 'Built Supply Pod III',
        image => 'v2/supply_pod3',
    },
    supply_pod4 => {
        name => 'Built Supply Pod IV',
        image => 'v2/supply_pod4',
    },
    supply_pod5 => {
        name => 'Built Supply Pod V',
        image => 'v2/supply_pod5',
    },
    probe => {
        name => 'Built Probe',
    },
    short_range_colony_ship => {
        name => 'Built Short Range Colony Ship',
    },
    colony_ship => {
        name => 'Built Colony Ship',
    },
    spy_pod => {
        name => 'Built Spy Pod',
    },
    cargo_ship => {
        name => 'Built Cargo Ship',
    },
    space_station => {
        name => 'Built Space Station Hull',
    },
    smuggler_ship => {
        name => 'Built Smuggler Ship',
    },
    mining_platform_ship => {
        name => 'Built Mining Platform Ship',
    },
    terraforming_platform_ship => {
        name => 'Built Terraforming Platform Ship',
    },
    gas_giant_settlement_ship => {
        name => 'Built Gas Giant Settlement Platform Ship',
    },
    scow => {
        name  => 'Built Scow',
        image => 'v2/scow',
    },
    scow_large => {
        name => 'Built Large Scow',
        image => 'v2/scow_large',
    },
    scow_mega => {
        name => 'Built Mega Scow',
        image => 'v2/scow_mega',
    },
    scow_fast => {
        name => 'Built Fast Scow',
        image => 'v2/scow_fast',
    },
    dory => {
        name => 'Built Dory',
    },
    barge => {
        name => 'Built Barge',
    },
    placebo => {
        name => 'Built Placebo',
    },
    placebo2 => {
        name => 'Built Placebo II',
    },
    placebo3 => {
        name => 'Built Placebo III',
    },
    placebo4 => {
        name => 'Built Placebo IV',
    },
    placebo5 => {
        name => 'Built Placebo V',
    },
    placebo6 => {
        name => 'Built Placebo VI',
    },
    bleeder => {
        name => 'Built Bleeder',
    },
    galleon => {
        name => 'Built Galleon',
    },
    hulk => {
        name => 'Built Hulk',
    },
    hulk_huge => {
        name => 'Built Huge Hulk',
    },
    hulk_fast => {
        name => 'Built Fast Hulk',
    },
    freighter => {
        name => 'Built Freighter',
    },
    thud => {
        name => 'Built Thud',
    },
    stake => {
        name => 'Built Stake',
    },
    sweeper => {
        name => 'Built Sweeper',
    },
    snark => {
        name => 'Built Snark',
    },
    snark2 => {
        name => 'Built Snark II',
    },
    snark3 => {
        name => 'Built Snark III',
    },
    drone => {
        name => 'Built Drone',
    },
    fighter => {
        name => 'Built Fighter',
    },
    spy_shuttle => {
        name => 'Built Spy Shuttle',
    },
    observatory_seeker => {
        name => 'Built Observatory Seeker',
    },
    security_ministry_seeker => {
        name => 'Built Security Ministry Seeker',
    },
    fissure_sealer => {
        name => 'Built Fissure Sealer',
    },
    spaceport_seeker => {
        name => 'Built SpacePort Seeker',
    },
    excavator => {
        name => 'Built Excavator',
    },
    detonator => {
        name => 'Built Detonator',
    },
    scanner => {
        name => 'Built Scanner',
    },
    surveyor => {
        name => 'Built Surveyor',
    },
    space_station_deployed => {
        name => 'Deployed a Space Station',
    },
    rutile_glyph => {
        name => 'Uncovered Rutile Glyph',
    },
    chromite_glyph => {
        name => 'Uncovered Chromite Glyph',
    },
    chalcopyrite_glyph => {
        name => 'Uncovered Chalcopyrite Glyph',
    },
    galena_glyph => {
        name => 'Uncovered Galena Glyph',
    },
    gold_glyph => {
        name => 'Uncovered Gold Glyph',
    },
    uraninite_glyph => {
        name => 'Uncovered Uraninite Glyph',
    },
    bauxite_glyph => {
        name => 'Uncovered Bauxite Glyph',
    },
    goethite_glyph => {
        name => 'Uncovered Goethite Glyph',
    },
    halite_glyph => {
        name => 'Uncovered Halite Glyph',
    },
    gypsum_glyph => {
        name => 'Uncovered Gypsum Glyph',
    },
    trona_glyph => {
        name => 'Uncovered Trona Glyph',
    },
    kerogen_glyph => {
        name => 'Uncovered Kerogen Glyph',
    },
    methane_glyph => {
        name => 'Uncovered Methane Glyph',
    },
    anthracite_glyph => {
        name => 'Uncovered Anthracite Glyph',
    },
    sulfur_glyph => {
        name => 'Uncovered Sulfur Glyph',
    },
    zircon_glyph => {
        name => 'Uncovered Zircon Glyph',
    },
    monazite_glyph => {
        name => 'Uncovered Monazite Glyph',
    },
    fluorite_glyph => {
        name => 'Uncovered Fluorite Glyph',
    },
    beryl_glyph => {
        name => 'Uncovered Beryl Glyph',
    },
    magnetite_glyph => {
        name => 'Uncovered Magnetite Glyph',
    },
    largest_colony => {
        name => 'Largest Colony',
        image => 'v2/largest_colony',
    },
    fastest_growing_colony => {
        name => 'Fastest Growing Colony',
        image => 'v2/fastest_growing_colony',
    },
    largest_empire => {
        name => 'Largest Empire',
        image => 'v2/largest_empire',
    },
    fastest_growing_empire => {
        name => 'Fastest Growing Empire',
        image => 'v2/fastest_growing_empire',
    },
    dirtiest_empire_in_the_game => {
        name => 'Dirtiest Empire In The Game',
        image => 'v2/dirtiest_empire_in_the_game',
    },
    dirtiest_empire_of_the_week => {
        name => 'Dirtiest Empire Of The Week',
        image => 'v2/dirtiest_empire_of_the_week',
    },
    best_defender_of_the_week => {
        name => 'Best Defender Of The Week',
        image => 'v2/best_defender_of_the_week',
    },
    best_defender_in_the_game => {
        name => 'Best Defender In The Game',
        image => 'v2/best_defender_in_the_game',
    },
    best_attacker_of_the_week => {
        name => 'Best Attacker Of The Week',
        image => 'v2/best_attacker_of_the_week',
    },
    best_attacker_in_the_game => {
        name => 'Best Attacker In The Game',
        image => 'v2/best_attacker_in_the_game',
    },
    most_improved_spy_of_the_week => {
        name => 'Most Improved Spy Of The Week',
        image => 'v2/most_improved_spy_of_the_week',
    },
    dirtiest_spy_in_the_game => {
        name => 'Dirtiest Spy In The Game',
        image => 'v2/dirtiest_spy_in_the_game',
    },
    dirtiest_spy_of_the_week => {
        name => 'Dirtiest Spy Of The Week',
        image => 'v2/dirtiest_spy_of_the_week',
    },
    best_defensive_spy_of_the_week => {
        name => 'Best Defensive Spy Of The Week',
        image => 'v2/best_defensive_spy_of_the_week',
    },
    best_defensive_spy_in_the_game => {
        name => 'Best Defensive Spy In The Game',
        image => 'v2/best_defensive_spy_in_the_game',
    },
    best_offensive_spy_of_the_week => {
        name => 'Best Offensive Spy Of The Week',
        image => 'v2/best_offensive_spy_of_the_week',
    },
    best_offensive_spy_in_the_game => {
        name => 'Best Offensive Spy In The Game',
        image => 'v2/best_offensive_spy_in_the_game',
    },
    best_spy_of_the_week => {
        name => 'Best Spy Of The Week',
        image => 'v2/best_spy_of_the_week',
    },
    best_spy_in_the_game => {
        name => 'Best Spy In The Game',
        image => 'v2/best_spy_in_the_game',
    },
    pleased_to_meet_you => {
        name => 'Meeting the Lacunans',
    },
    P1 => {
        name => 'Settled P1 Type Planet',
    },  
    P2 => {
        name => 'Settled P2 Type Planet',
    },  
    P3 => {
        name => 'Settled P3 Type Planet',
    },  
    P4 => {
        name => 'Settled P4 Type Planet',
    },  
    P5 => {
        name => 'Settled P5 Type Planet',
    },  
    P6 => {
        name => 'Settled P6 Type Planet',
    },  
    P7 => {
        name => 'Settled P7 Type Planet',
    },  
    P8 => {
        name => 'Settled P8 Type Planet',
    },  
    P9 => {
        name => 'Settled P9 Type Planet',
    },  
    P10 => {
        name => 'Settled P10 Type Planet',
    },  
    P11 => {
        name => 'Settled P11 Type Planet',
    },  
    P12 => {
        name => 'Settled P12 Type Planet',
    },  
    P13 => {
        name => 'Settled P13 Type Planet',
    },  
    P14 => {
        name => 'Settled P14 Type Planet',
    },  
    P15 => {
        name => 'Settled P15 Type Planet',
    },  
    P16 => {
        name => 'Settled P16 Type Planet',
    },  
    P17 => {
        name => 'Settled P17 Type Planet',
    },  
    P18 => {
        name => 'Settled P18 Type Planet',
    },  
    P19 => {
        name => 'Settled P19 Type Planet',
    },  
    P20 => {
        name => 'Settled P20 Type Planet',
    },  
    P21 => {
        name => 'Settled P21 Type Planet',
    },  
    P22 => {
        name => 'Settled P22 Type Planet',
    },  
    P23 => {
        name => 'Settled P23 Type Planet',
    },  
    P24 => {
        name => 'Settled P24 Type Planet',
    },  
    P25 => {
        name => 'Settled P25 Type Planet',
    },  
    P26 => {
        name => 'Settled P26 Type Planet',
    },  
    P27 => {
        name => 'Settled P27 Type Planet',
    },  
    P28 => {
        name => 'Settled P28 Type Planet',
    },  
    P29 => {
        name => 'Settled P29 Type Planet',
    },  
    P30 => {
        name => 'Settled P30 Type Planet',
    },  
    P31 => {
        name => 'Settled P31 Type Planet',
    },  
    P32 => {
        name => 'Settled P32 Type Planet',
    },  
    P33 => {
        name => 'Settled P33 Type Planet',
    },  
    P34 => {
        name => 'Settled P34 Type Planet',
    },  
    P35 => {
        name => 'Settled P35 Type Planet',
    },  
    P36 => {
        name => 'Settled P36 Type Planet',
    },  
    P37 => {
        name => 'Settled P37 Type Planet',
    },  
    P38 => {
        name => 'Settled P38 Type Planet',
    },  
    P39 => {
        name => 'Settled P39 Type Planet',
    },  
    P40 => {
        name => 'Settled P40 Type Planet',
    },  
    G1 => {
        name => 'Settled G1 Type Gas Giant',
    },  
    G2 => {
        name => 'Settled G2 Type Gas Giant',
    },  
    G3 => {
        name => 'Settled G3 Type Gas Giant',
    },  
    G4 => {
        name => 'Settled G4 Type Gas Giant',
    },  
    G5 => {
        name => 'Settled G5 Type Gas Giant',
    }, 
    A1 => {
        name => 'Mined A1 Type Asteroid',
    },
    A2 => {
        name => 'Mined A2 Type Asteroid',
    },
    A3 => {
        name => 'Mined A3 Type Asteroid',
    },
    A4 => {
        name => 'Mined A4 Type Asteroid',
    },
    A5 => {
        name => 'Mined A5 Type Asteroid',
    },
    A6 => {
        name => 'Mined A6 Type Asteroid',
    },
    A7 => {
        name => 'Mined A7 Type Asteroid',
    },
    A8 => {
        name => 'Mined A8 Type Asteroid',
    },
    A9 => {
        name => 'Mined A9 Type Asteroid',
    },
    A10 => {
        name => 'Mined A10 Type Asteroid',
    },
    A11 => {
        name => 'Mined A11 Type Asteroid',
    },
    A12 => {
        name => 'Mined A12 Type Asteroid',
    },
    A13 => {
        name => 'Mined A13 Type Asteroid',
    },
    A14 => {
        name => 'Mined A14 Type Asteroid',
    },
    A15 => {
        name => 'Mined A15 Type Asteroid',
    },
    A16 => {
        name => 'Mined A16 Type Asteroid',
    },
    A17 => {
        name => 'Mined A17 Type Asteroid',
    },
    A18 => {
        name => 'Mined A18 Type Asteroid',
    },
    A19 => {
        name => 'Mined A19 Type Asteroid',
    },
    A20 => {
        name => 'Mined A20 Type Asteroid',
    },
    A21 => {
        name => 'Mined Debris Field',
    },
    A22 => {
        name => 'Mined A22 Type Asteroid',
    },
    A23 => {
        name => 'Mined A23 Type Asteroid',
    },
    A24 => {
        name => 'Mined A24 Type Asteroid',
    },
    A25 => {
        name => 'Mined A25 Type Asteroid',
    },
    A26 => {
        name => 'Mined A26 Type Asteroid',
    },
    buildingX => {
        name => 'Built Building outside range',
    },
    building1 => {
        name => 'Built Level 1 Building',
    },
    building2 => {
        name => 'Built Level 2 Building',
    },
    building3 => {
        name => 'Built Level 3 Building',
    },
    building4 => {
        name => 'Built Level 4 Building',
    },
    building5 => {
        name => 'Built Level 5 Building',
    },
    building6 => {
        name => 'Built Level 6 Building',
    },
    building7 => {
        name => 'Built Level 7 Building',
    },
    building8 => {
        name => 'Built Level 8 Building',
    },
    building9 => {
        name => 'Built Level 9 Building',
    },
    building10 => {
        name => 'Built Level 10 Building',
    },
    building11 => {
        name => 'Built Level 11 Building',
    },
    building12 => {
        name => 'Built Level 12 Building',
    },
    building13 => {
        name => 'Built Level 13 Building',
    },
    building14 => {
        name => 'Built Level 14 Building',
    },
    building15 => {
        name => 'Built Level 15 Building',
    },
    building16 => {
        name => 'Built Level 16 Building',
    },
    building17 => {
        name => 'Built Level 17 Building',
    },
    building18 => {
        name => 'Built Level 18 Building',
    },
    building19 => {
        name => 'Built Level 19 Building',
    },
    building20 => {
        name => 'Built Level 20 Building',
    },
    building21 => {
        name => 'Built Level 21 Building',
    },
    building22 => {
        name => 'Built Level 22 Building',
    },
    building23 => {
        name => 'Built Level 23 Building',
    },
    building24 => {
        name => 'Built Level 24 Building',
    },
    building25 => {
        name => 'Built Level 25 Building',
    },
    building26 => {
        name => 'Built Level 26 Building',
    },
    building27 => {
        name => 'Built Level 27 Building',
    },
    building28 => {
        name => 'Built Level 28 Building',
    },
    building29 => {
        name => 'Built Level 29 Building',
    },
    building30 => {
        name => 'Built Level 30 Building',
    },
    building31 => {
        name => 'Built Level 31 Building',
    },
    SAW => {
        name => 'Built Shield Against Weapons',
    },
    OperaHouse => {
        name => 'Installed Opera House',
    },
    ArtMuseum => {
        name => 'Installed Art Museum',
    },
    CulinaryInstitute => {
        name => 'Installed Culinary Institute',
    },
    IBS => {
        name => 'Installed Interstellar Broadcast System',
    },
    StationCommand => {
        name => 'Installed Station Command Center',
    },
    Parliament => {
        name => 'Installed Parliament',
    },
    Warehouse => {
        name => 'Installed Warehouse',
    },
    DistributionCenter => {
        name => 'Built Distribution Center',
    },
    AtmosphericEvaporator => {
        name => 'Built Atmospheric Evaporator',
    },
    GreatBallOfJunk => {
        name => 'Built Great Ball of Junk',
    },
    PyramidJunkSculpture => {
        name => 'Built Pyramid Junk Sculpture',
    },
    SpaceJunkPark => {
        name => 'Built Space Junk Park',
    },
    MetalJunkArches => {
        name => 'Built Metal Junk Arches',
    },
    JunkHengeSculpture => {
        name => 'Built Junk Henge Sculpture',
    },
    Capitol => {
        name => 'Built Capitol',
    },
    ThemePark => {
        name => 'Built Theme Park',
    },
    BlackHoleGenerator => {
        name => 'Discovered a Black Hole Generator',
    },
    HallsOfVrbansk => {
        name => 'Discovered the Halls of Vrbansk',
    },
    GratchsGauntlet => {
        name => 'Discovered Gratch\'s Gauntlet',
    },
    KasternsKeep => {
        name => 'Discovered Kastern\'s Keep',
    },
    TheDillonForge => {
        name => 'Discovered the Dillon Forge',
    },
    SupplyPod => {
        name => 'Received Supply Pod',
    },
    SubspaceSupplyDepot => {
        name => 'Received Subspace Supply Depot',
    },
    Stockpile => {
        name => 'Built Stockpile',
    },
    Algae => {
        name => 'Built Algae Cropper',
    },
    Apple => {
        name => 'Built Apple Orchard',
    },
    Bean => {
        name => 'Built Bean Plantation',
    },
    Beeldeban => {
        name => 'Built Beeldeban Herder',
    },
    Bread => {
        name => 'Built Bakery',
    },
    Burger => {
        name => 'Built Burger Factory',
    },
    Cheese => {
        name => 'Built Cheese Factory',
    },
    Chip => {
        name => 'Built Chip Frier',
    },
    Cider => {
        name => 'Built Cider Bottler',
    },
    Corn => {
        name => 'Built Corn Plantation',
    },
    CornMeal => {
        name => 'Built Corn Meal Grinder',
    },
    Lagoon => {
        name => 'Discovered a Lagoon',
    },
    Sand => {
        name => 'Discovered a Patch of Sand',
    },
    Grove => {
        name => 'Discovered a Grove of Trees',
    },
    Crater => {
        name => 'Discovered a Crater',
    },
    DeployedBleeder => {
        name => 'Deployed a Bleeder',
    },
    Dairy => {
        name => 'Built Dairy Farm',
    },
    Denton => {
        name => 'Built Denton Root Farm',
    },
    Development => {
        name => 'Built Development Ministry',
    },
    Embassy => {
        name => 'Built Embassy',
    },
    EnergyReserve => {
        name => 'Built Energy Reserve',
    },
    Entertainment => {
        name => 'Built Entertainment District',
    },
    Espionage => {
        name => 'Built Espionage Ministry',
    },
    LCOTa => {
        name => 'Discovered Lost City of Tyleon (A)',
    },
    LCOTb => {
        name => 'Discovered Lost City of Tyleon (B)',
    },
    LCOTc => {
        name => 'Discovered Lost City of Tyleon (C)',
    },
    LCOTd => {
        name => 'Discovered Lost City of Tyleon (D)',
    },
    LCOTe => {
        name => 'Discovered Lost City of Tyleon (E)',
    },
    LCOTf => {
        name => 'Discovered Lost City of Tyleon (F)',
    },
    LCOTg => {
        name => 'Discovered Lost City of Tyleon (G)',
    },
    LCOTh => {
        name => 'Discovered Lost City of Tyleon (H)',
    },
    LCOTi => {
        name => 'Discovered Lost City of Tyleon (I)',
    },
    SSLa => {
        name => 'Built Space Station Lab (A)',
    },
    SSLb => {
        name => 'Built Space Station Lab (B)',
    },
    SSLc => {
        name => 'Built Space Station Lab (C)',
    },
    SSLd => {
        name => 'Built Space Station Lab (D)',
    },
    MalcudField => {
        name => 'Discovered a Malcud Field',
    },
    Fissure => {
        name => 'Caused a Fissure',
    },
    Ravine => {
        name => 'Discovered a Ravine',
    },
    AlgaePond => {
        name => 'Discovered a Algae Pond',
    },
    LapisForest => {
        name => 'Discovered a Lapis Forest',
    },
    BeeldebanNest => {
        name => 'Discovered a Beeldeban Nest',
    },
    CrashedShipSite => {
        name => 'Discovered a Crashed Ship Site',
    },
    CitadelOfKnope => {
        name => 'Discovered the Citadel of Knope',
    },
    KalavianRuins => {
        name => 'Discovered the Kalavian Ruins',
    },
    MassadsHenge => {
        name => 'Discovered Massad\'s Henge',
    },
    PantheonOfHagness => {
        name => 'Discovered the Pantheon of Hagness',
    },
    Volcano => {
        name => 'Discovered a Volcano',
    },
    TempleOfTheDrajilites => {
        name => 'Discovered the Temple of the Drajilites',
    },
    GeoThermalVent => {
        name => 'Discovered a Geo Thermal Vent',
    },
    OracleOfAnid => {
        name => 'Discovered the Oracle of Anid',
    },
    InterDimensionalRift => {
        name => 'Discovered an Interdimensional Rift',
    },
    NaturalSpring => {
        name => 'Discovered a Natural Spring',
    },
    LibraryOfJith => {
        name => 'Discovered the Library of Jith',
    },
    EssentiaVein => {
        name => 'Discovered a vein of Essentia',
    },
    Fission => {
        name => 'Built Fission Reactor',
    },
    FoodReserve => {
        name => 'Built Food Reserve',
    },
    Fusion => {
        name => 'Built Fusion Reactor',
    },
    GasGiantLab => {
        name => 'Built Gas Giant Lab',
    },
    GasGiantPlatform => {
        name => 'Built Gas Giant Platform',
    },
    Geo => {
        name => 'Built Geo Energy Plant',
    },
    Hydrocarbon => {
        name => 'Built Hydrocarbon Energy Plant',
    },
    Intelligence => {
        name => 'Built Intelligence Ministry',
    },
    IntelTraining => {
        name => 'Built Intel Training Facility',
    },
    Lapis => {
        name => 'Built Lapis Orchard',
    },
    Lake => {
        name => 'Discovered a Lake',
    },
    Malcud => {
        name => 'Built Malcud Fungus Farm',
    },
    MayhemTraining => {
        name => 'Built Mayhem Training Facility',
    },
    Mine => {
        name => 'Built Mine',
    },
    MiningMinistry => {
        name => 'Built Mining Ministry',
    },
    MiningPlatform => {
        name => 'Built Mining Platform',
    },
    Network19 => {
        name => 'Built Network 19 Affiliate',
    },
    Observatory => {
        name => 'Built Observatory',
    },
    OreRefinery => {
        name => 'Built Ore Refinery',
    },
    OreStorage => {
        name => 'Built Ore Storage Tank',
    },
    Pancake => {
        name => 'Built Pancake Factory',
    },
    Park => {
        name => 'Built Park',
    },
    Pie => {
        name => 'Built Pie Factory',
    },
    PlanetaryCommand => {
        name => 'Built Planetary Command Center',
    },
    PoliticsTraining => {
        name => 'Built Politics Training Facility',
    },
    Potato => {
        name => 'Built Potato Plantation',
    },
    Propulsion => {
        name => 'Built Propulsion Factory',
    },
    Oversight => {
        name => 'Built Oversight Ministry',
    },
    RockyOutcrop => {
        name => 'Discovered a Rocky Outcropping',
    },
    Security => {
        name => 'Built Security Ministry',
    },
    Shake => {
        name => 'Built Shake Factory',
    },
    Shipyard => {
        name => 'Built Shipyard',
    },
    Singularity => {
        name => 'Built Singularity Energy Plant',
    },
    Soup => {
        name => 'Built Soup Cannery',
    },
    SpacePort => {
        name => 'Built Space Port',
    },
    Syrup => {
        name => 'Built Syrup Bottler',
    },
    TerraformingLab => {
        name => 'Built Terraforming Lab',
    },
    GeneticsLab => {
        name => 'Built Genetics Lab',
    },
    Archaeology => {
        name => 'Built Archaeology Ministry',
    },
    TerraformingPlatform => {
        name => 'Built Terraforming Platform',
    },
    TheftTraining => {
        name => 'Built Theft Training Facility',
    },
    Trade => {
        name => 'Built Trade Ministry',
    },
    Transporter => {
        name => 'Built Subspace Transporter',
    },
    University => {
        name => 'Built University',
    },
    WasteEnergy => {
        name => 'Built Waste Energy Plant',
    },
    WasteExchanger => {
        name => 'Built Waste Exchanger',
    },
    WasteRecycling => {
        name => 'Built Waste Recycling Center',
    },
    WasteSequestration => {
        name => 'Built Waste Sequestration Well',
    }, 
    WasteDigester => {
        name => 'Built Waste Digester',
    },
    WasteTreatment => {
        name => 'Built Waste Treatment Center',
    },
    WaterProduction => {
        name => 'Built Water Production Plant',
    },
    WaterPurification => {
        name => 'Built Water Purification Plant',
    },
    WaterReclamation => {
        name => 'Built Water Reclamation Plant',
    },
    WaterStorage => {
        name => 'Built Water Storage Tank',
    },
    Wheat => {
        name => 'Built Wheat Farm',
    },
    Beach1 => {
        name => 'Built Beach (section 1)',
    },
    Beach2 => {
        name => 'Built Beach (section 2)',
    },
    Beach3 => {
        name => 'Built Beach (section 3)',
    },
    Beach4 => {
        name => 'Built Beach (section 4)',
    },
    Beach5 => {
        name => 'Built Beach (section 5)',
    },
    Beach6 => {
        name => 'Built Beach (section 6)',
    },
    Beach7 => {
        name => 'Built Beach (section 7)',
    },
    Beach8 => {
        name => 'Built Beach (section 8)',
    },
    Beach9 => {
        name => 'Built Beach (section 9)',
    },
    Beach10 => {
        name => 'Built Beach (section 10)',
    },
    Beach11 => {
        name => 'Built Beach (section 11)',
    },
    Beach12 => {
        name => 'Built Beach (section 12)',
    },
    Beach13 => {
        name => 'Built Beach (section 13)',
    },
    MunitionsLab => {
        name => 'Built Munitions Lab',
    },
    PilotTraining => {
        name => 'Built Pilot Training Facility',
    },
    LuxuryHousing => {
        name => 'Built Luxury Housing',
    },
    MissionCommand => {
        name => 'Built Mission Command',
    },
    CloakingLab => {
        name => 'Built Cloaking Lab',
    },
    AmalgusMeadow => {
        name => 'Discovered an Amalgus Meadow',
    },
    DentonBrambles => {
        name => 'Discovered Denton Brambles',
    },
    MercenariesGuild => {
        name => 'Built Mercenaries Guild',
    },
    PoliceStation => {
        name => 'Built Police Station',
    },
    #DiablotinDefeated => {
    #    name => '',
    #},
    #SabenDefeated => {
    #    name => '',
    #},
    TrelDefeated => {
        name => 'Won the Four Trel Colonies tournament',
    },
    TournamentVictory => {
        name => 'Won a tournament',
    },
    '20Stars' => {
        name => 'Won the Twenty Stars tournament',
    },
    'flipped' => {
        name => 'Ran a successful insurrection',
    },
    abandoned_colony => {
        name => 'Abandoned a Colony',
    },
    fissure_explosion => {
        name => 'Suffered a Fissure Explosion on a Colony',
    },
    fissure_repair => {
        name => 'Closed a Fissure',
    },
    patch => {
        name => 'Submitted an accepted patch',
    },
};

sub name {
    my $self = shift;
    return MEDALS->{$self->type}{name};
}

sub image {
    my $self = shift;
    return MEDALS->{$self->type}{image} || $self->type;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
