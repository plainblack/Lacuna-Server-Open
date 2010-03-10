package Lacuna::DB::Building::Food::Farm::Apple;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Apple';
}

sub building_prereq {
    return {'Lacuna::DB::Building::PlanetaryCommand'=>5};
}

sub min_orbit {
    return 3;
}

sub max_orbit {
    return 3;
}

sub image {
    return 'apples';
}

sub name {
    return 'Apple Orchard';
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
    return 5;
}

sub time_to_build {
    return 600;
}

sub food_consumption {
    return 5;
}

sub apple_production {
    return 46;
}

sub energy_consumption {
    return 1;
}

sub ore_consumption {
    return 1;
}

sub water_consumption {
    return 9;
}

sub waste_production {
    return 16;
}

sub waste_consumption {
    return 3;
}



no Moose;
__PACKAGE__->meta->make_immutable;
