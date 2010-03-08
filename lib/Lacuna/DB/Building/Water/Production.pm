package Lacuna::DB::Building::Water::Production;

use Moose;
extends 'Lacuna::DB::Building::Water';

sub controller_class {
    return 'Lacuna::Building::WaterProduction';
}

sub university_prereq {
    return 3;
}

sub image {
    return 'waterproduction';
}

sub name {
    return 'Water Production Plant';
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
    return 20;
}

sub time_to_build {
    return 950;
}

sub food_consumption {
    return 10;
}

sub energy_consumption {
    return 100;
}

sub ore_consumption {
    return 100;
}

sub water_production {
    return 170;
}

sub waste_production {
    return 20;
}



no Moose;
__PACKAGE__->meta->make_immutable;
