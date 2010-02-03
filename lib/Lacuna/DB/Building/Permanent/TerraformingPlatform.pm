package Lacuna::DB::Building::Permanent::TerraformingPlatform;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

has '+image' => ( 
    default => 'terraforming-platform', 
);

has '+name' => (
    default => 'Terraforming Platform',
);

has '+food_to_build' => (
    default => 1000,
);

has '+energy_to_build' => (
    default => 1000,
);

has '+ore_to_build' => (
    default => 1000,
);

has '+water_to_build' => (
    default => 1000,
);

has '+waste_to_build' => (
    default => 1000,
);

has '+time_to_build' => (
    default => 600,
);

has '+food_consumption' => (
    default => 45,
);

has '+energy_consumption' => (
    default => 45,
);

has '+ore_consumption' => (
    default => 45,
);

has '+water_consumption' => (
    default => 45,
);

has '+waste_production' => (
    default => 100,
);

no Moose;
__PACKAGE__->meta->make_immutable;
