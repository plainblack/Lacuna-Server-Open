package Lacuna::DB::Building::Food::Factory::Pancake;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Pancake';
}

sub min_orbit {
    return 3;
}

sub max_orbit {
    return 4;
}

sub building_prereq {
    return {'Lacuna::DB::Building::Food::Farm::Potato'=>1};
}

sub image {
    return 'pancake';
}

sub name {
    return 'Potato Pancake Factory';
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
    return 2000;
}

sub food_consumption {
    return 150;
}

sub pancake_production {
    return 90;
}

sub energy_consumption {
    return 25;
}

sub water_consumption {
    return 25;
}

sub waste_production {
    return 25;
}



no Moose;
__PACKAGE__->meta->make_immutable;
