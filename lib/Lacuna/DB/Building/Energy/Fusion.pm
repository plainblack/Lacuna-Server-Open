package Lacuna::DB::Building::Energy::Fusion;

use Moose;
extends 'Lacuna::DB::Building::Energy';

sub controller_class {
        return 'Lacuna::Building::Fusion';
}

sub university_prereq {
    return 10;
}

sub image {
    return 'fusion';
}

sub name {
    return 'Fusion Energy Plant';
}

sub food_to_build {
    return 500;
}

sub energy_to_build {
    return 650;
}

sub ore_to_build {
    return 575;
}

sub water_to_build {
    return 480;
}

sub waste_to_build {
    return 200;
}

sub time_to_build {
    return 790;
}

sub food_consumption {
    return 5;
}

sub energy_consumption {
    return 50;
}

sub energy_production {
    return 517;
}

sub ore_consumption {
    return 30;
}

sub water_consumption {
    return 60;
}

sub waste_production {
    return 8;
}


no Moose;
__PACKAGE__->meta->make_immutable;
