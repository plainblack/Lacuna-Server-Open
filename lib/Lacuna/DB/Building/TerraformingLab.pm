package Lacuna::DB::Building::TerraformingLab;

use Moose;
extends 'Lacuna::DB::Building';

has '+image' => ( 
    default => 'terraforming-lab', 
);

has '+name' => (
    default => 'Terraforming Lab',
);

has '+food_to_build' => (
    default => -250,
);

has '+energy_to_build' => (
    default => -250,
);

has '+ore_to_build' => (
    default => -500,
);

has '+water_to_build' => (
    default => -100,
);

has '+waste_to_build' => (
    default => 250,
);

has '+time_to_build' => (
    default => 900,
);

has '+food_consumption' => (
    default => 50,
);

has '+energy_consumption' => (
    default => 50,
);

has '+ore_consumption' => (
    default => 50,
);

has '+water_consumption' => (
    default => 50,
);

has '+waste_production' => (
    default => 100,
);


no Moose;
__PACKAGE__->meta->make_immutable;
