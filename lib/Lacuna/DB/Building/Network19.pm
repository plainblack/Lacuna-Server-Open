package Lacuna::DB::Building::Network19;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
    return 'Lacuna::Building::Network19';
}

sub university_prereq {
    return 2;
}

sub image {
    return 'network19';
}

sub name {
    return 'Network 19 Affliate';
}

sub food_to_build {
    return 100;
}

sub energy_to_build {
    return 100;
}

sub ore_to_build {
    return 100;
}

sub water_to_build {
    return 100;
}

sub waste_to_build {
    return 100;
}

sub time_to_build {
    return 200;
}

sub food_consumption {
    return 30;
}

sub energy_consumption {
    return 95;
}

sub ore_consumption {
    return 2;
}

sub water_consumption {
    return 45;
}

sub waste_production {
    return 15;
}

sub happiness_production {
    return 60;
}



no Moose;
__PACKAGE__->meta->make_immutable;
