package Lacuna::DB::Building::Food::Factory::Shake;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
    return 'Lacuna::Building::Shake';
}

sub min_orbit {
    return 2;
}

sub max_orbit {
    return 4;
}

sub building_prereq {
    return {'Lacuna::DB::Food::Farm::Beeldeban'=>1};
}

sub image {
    return 'shake';
}

sub name {
    return 'Beeldeban Protein Shake Factory';
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
    return 150;
}

sub shake_production {
    return 100;
}

sub energy_consumption {
    return 25;
}

sub ore_consumption {
    return 5;
}

sub water_consumption {
    return 40;
}

sub waste_production {
    return 20;
}



no Moose;
__PACKAGE__->meta->make_immutable;
