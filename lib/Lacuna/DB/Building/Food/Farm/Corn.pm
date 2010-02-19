package Lacuna::DB::Building::Food::Farm::Corn;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Corn';
}

sub image {
    return 'corn';
}

sub name {
    return 'Corn Plantation';
}

sub food_to_build {
    return 10;
}

sub energy_to_build {
    return 100;
}

sub ore_to_build {
    return 55;
}

sub water_to_build {
    return 10;
}

sub waste_to_build {
    return 10;
}

sub time_to_build {
    return 60;
}

sub food_consumption {
    return 5;
}

sub corn_production {
    return 44;
}

sub energy_consumption {
    return 1;
}

sub ore_consumption {
    return 11;
}

has '+water_consumption' => (
    default => -10,
);

sub waste_production {
    return 22;
}



no Moose;
__PACKAGE__->meta->make_immutable;
