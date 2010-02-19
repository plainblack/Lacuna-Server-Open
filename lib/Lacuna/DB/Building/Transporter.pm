package Lacuna::DB::Building::Transporter;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::Transporter';
}

has '+image' => ( 
    default => 'transporter', 
);

has '+name' => (
    default => 'Subspace Transporter',
);

has '+food_to_build' => (
    default => 1200,
);

has '+energy_to_build' => (
    default => 1400,
);

has '+ore_to_build' => (
    default => 1500,
);

has '+water_to_build' => (
    default => 1200,
);

has '+waste_to_build' => (
    default => 900,
);

has '+time_to_build' => (
    default => 1150,
);

has '+food_consumption' => (
    default => 5,
);

has '+energy_consumption' => (
    default => 20,
);

has '+ore_consumption' => (
    default => 13,
);

has '+water_consumption' => (
    default => 20,
);

has '+waste_production' => (
    default => 2,
);


no Moose;
__PACKAGE__->meta->make_immutable;
