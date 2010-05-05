package Lacuna::DB::Medals;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('medals');
__PACKAGE__->add_columns(
    type                    => { data_type => 'char', size => 30, is_nullable => 0 },
    empire_id               => { data_type => 'int', size => 11, is_nullable => 0 },
    public                  => { data_type => 'int', size => 1, default_value => 1 },
    datestamp               => { data_type => 'datetime', is_nullable => 0, default_value => DateTime->now },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');

sub format_datestamp {
    my ($self) = @_;
    return format_date($self->datestamp);
}

use constant MEDALS => {
    spy                 => 'Built Spy',
    counter_spy         => 'Built Counter Spy',
    pleased_to_meet_you => 'Meeting the Lacunans',
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
    building1           => 'Built Level 1 Building',
    building2           => 'Built Level 2 Building',
    building3           => 'Built Level 3 Building',
    building4           => 'Built Level 4 Building',
    building5           => 'Built Level 5 Building',
    building6           => 'Built Level 6 Building',
    building7           => 'Built Level 7 Building',
    building8           => 'Built Level 8 Building',
    building9           => 'Built Level 9 Building',
    building10          => 'Built Level 10 Building',
    building11          => 'Built Level 11 Building',
    building12          => 'Built Level 12 Building',
    building13          => 'Built Level 13 Building',
    building14          => 'Built Level 14 Building',
    building15          => 'Built Level 15 Building',
    building16          => 'Built Level 16 Building',
    building17          => 'Built Level 17 Building',
    building18          => 'Built Level 18 Building',
    building19          => 'Built Level 19 Building',
    building20          => 'Built Level 20 Building',
    building21          => 'Built Level 21 Building',
    building22          => 'Built Level 22 Building',
    building23          => 'Built Level 23 Building',
    building24          => 'Built Level 24 Building',
    building25          => 'Built Level 25 Building',
    building26          => 'Built Level 26 Building',
    building27          => 'Built Level 27 Building',
    building28          => 'Built Level 28 Building',
    building29          => 'Built Level 29 Building',
    building30          => 'Built Level 30 Building',
    Algae               => 'Build Algae Cropper',
    Apple               => 'Built Apple Orchard',
    Bean                => 'Built Bean Plantation',
    Beeldeban           => 'Built Beeldeban Herder',
    Bread               => 'Built Bakery',
    Burger              => 'Build Burger Factory',
    Cheese              => 'Build Cheese Factory',
    Chip                => 'Built Chip Frier',
    Cider               => 'Built Cider Bottler',
    Corn                => 'Built Corn Plantation',
    CornMeal            => 'Built Corn Meal Grinder',
    Dairy               => 'Built Dairy Farm',
    Denton              => 'Built Denton Root Farm',
    Development         => 'Built Development Ministry',
    Embassy             => 'Built Embassy',
    EnergyReserve       => 'Built Energy Reserve',
    Entertainment       => 'Built Entertainment District',
    Espionage           => 'Built Espionage Ministry',
    Fission             => 'Built Fission Reactor',
    FoodReserve         => 'Built Food Reserve',
    Fusion              => 'Built Fusion Reactor',
    GasGiantLab         => 'Built Gas Giant Lab',
    GasGiantPlatform    => 'Built Gas Giant Platform',
    Geo                 => 'Built Geo Energy Plant',
    Hydrocarbon         => 'Built Hydrocarbon Energy Plant',
    Intelligence        => 'Built Intelligence Ministry',
    Lapis               => 'Built Lapis Orchard',
    Malcud              => 'Built Malcud Fungus Farm',
    Mine                => 'Built Mine',
    MiningMinistry      => 'Built Mining Ministry',
    MiningPlatform      => 'Built Mining Platform',
    Network19           => 'Built Network 19 Affiliate',
    Observatory         => 'Built Observatory',
    OreRefinery         => 'Built Ore Refinery',
    OreStorage          => 'Built Ore Storage Tank',
    Pancake             => 'Built Pancake Factory',
    Park                => 'Built Park',
    Pie                 => 'Built Pie Factory',
    PlanetaryCommand    => 'Built Planetary Command Center',
    Potato              => 'Built Potato Plantation',
    Propulsion          => 'Built Propulsion Factory',
    RND                 => 'Built Research Lab',
    Security            => 'Built Security Ministry',
    Shake               => 'Built Shake Factory',
    Shipyard            => 'Built Shipyard',
    Singularity         => 'Built Singularity Energy Plant',
    Soup                => 'Built Soup Cannery',
    SpacePort           => 'Built Space Port',
    Syrup               => 'Built Syrup Bottler',
    TerraformingLab     => 'Built Terraforming Lab',
    TerraformingPlatform=> 'Built Terraforming Platform',
    Trade               => 'Built Trade Ministry',
    Transporter         => 'Built Subspace Transporter',
    University          => 'Built University',
    WasteEnergy         => 'Built Waste Energy Plant',
    WasteRecycling      => 'Built Waste Recycling Center',
    WasteSequestration  => 'Built Waste Sequestration Well', 
    WasteTreatment      => 'Built Waste Treatment Center',
    WaterProduction     => 'Built Water Production Plant',
    WaterPurification   => 'Built Water Purification Plant',
    WaterReclamation    => 'Built Water Reclamation Plant',
    WaterStorage        => 'Built Water Storage Tank',
    Wheat               => 'Built Wheat Farm',
};

sub name {
    my $self = shift;
    return MEDALS->{$self->type};
}

sub image {
    my $self = shift;
    return $self->type;
}

no Moose;
__PACKAGE__->meta->make_immutable;
