package Lacuna::DB::Building::Food::Farm::Lapis;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Lapis';
}

sub building_prereq {
    return {'Lacuna::DB::Building::PlanetaryCommand'=>5};
}

sub min_orbit {
    return 2;
}

sub max_orbit {
    return 2;
}

sub image {
    return 'lapis';
}

sub name {
    return 'Lapis Orchard';
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

sub lapis_production {
    return 75;
}

sub energy_consumption {
    return 2;
}

sub ore_consumption {
    return 10;
}

sub water_consumption {
    return 10;
}

sub waste_production {
    return 50;
}



no Moose;
__PACKAGE__->meta->make_immutable;
