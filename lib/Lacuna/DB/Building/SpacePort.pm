package Lacuna::DB::Building::SpacePort;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
    return 'Lacuna::Building::SpacePort';
}

sub university_prereq {
    return 3;
}

sub image {
    return 'space-port';
}

sub name {
    return 'Space Port';
}

sub food_to_build {
    return 800;
}

sub energy_to_build {
    return 900;
}

sub ore_to_build {
    return 500;
}

sub water_to_build {
    return 500;
}

sub waste_to_build {
    return 400;
}

sub time_to_build {
    return 850;
}

sub food_consumption {
    return 100;
}

sub energy_consumption {
    return 100;
}

sub ore_consumption {
    return 120;
}

sub water_consumption {
    return 150;
}

sub waste_production {
    return 100;
}


no Moose;
__PACKAGE__->meta->make_immutable;
