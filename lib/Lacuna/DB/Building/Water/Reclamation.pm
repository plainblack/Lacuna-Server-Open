package Lacuna::DB::Building::Water::Reclamation;

use Moose;
extends 'Lacuna::DB::Building::Water';

sub controller_class {
        return 'Lacuna::Building::Reclamation';
}

has '+image' => ( 
    default => 'water-reclamation', 
);

has '+name' => (
    default => 'Water Reclamation Facility',
);

has '+food_to_build' => (
    default => 100,
);

has '+energy_to_build' => (
    default => 100,
);

has '+ore_to_build' => (
    default => 100,
);

has '+water_to_build' => (
    default => 100,
);

has '+waste_to_build' => (
    default => 20,
);

has '+time_to_build' => (
    default => 95,
);

has '+food_consumption' => (
    default => 5,
);

has '+energy_consumption' => (
    default => 5,
);

has '+ore_consumption' => (
    default => 5,
);

has '+water_production' => (
    default => 200,
);

has '+waste_consumption' => (
    default => 100,
);



no Moose;
__PACKAGE__->meta->make_immutable;
