package Lacuna::DB::Building::Food::Factory::Bread;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Bread';
}

sub min_orbit {
    return 2;
}

sub max_orbit {
    return 4;
}

sub building_prereq {
    return {'Lacuna::DB::Food::Farm::Wheat'=>1};
}

sub image {
    return 'bread';
}

sub name {
    return 'Bread Bakery';
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

sub bread_production {
    return 75;
}

sub energy_consumption {
    return 50;
}

sub water_consumption {
    return 25;
}

sub waste_production {
    return 28;
}



no Moose;
__PACKAGE__->meta->make_immutable;
