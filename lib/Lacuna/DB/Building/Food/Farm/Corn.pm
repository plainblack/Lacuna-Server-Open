package Lacuna::DB::Building::Food::Farm::Corn;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
    return 'Lacuna::Building::Corn';
}

sub min_orbit {
    return 2;
}

sub max_orbit {
    return 3;
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
    return 600;
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

sub water_consumption {
    return 10;
}

sub waste_production {
    return 22;
}



no Moose;
__PACKAGE__->meta->make_immutable;
