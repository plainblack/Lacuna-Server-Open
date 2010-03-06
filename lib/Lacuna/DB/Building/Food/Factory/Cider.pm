package Lacuna::DB::Building::Food::Factory::Cider;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Cider';
}

sub image {
    return 'cider';
}

sub min_orbit {
    return 3;
}

sub max_orbit {
    return 3;
}

sub building_prereq {
    return {'Lacuna::DB::Food::Farm::Apple'=>1};
}

sub name {
    return 'Apple Cider Bottler';
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

sub cider_production {
    return 75;
}

sub energy_consumption {
    return 50;
}

sub water_consumption {
    return 50;
}

sub waste_production {
    return 100;
}



no Moose;
__PACKAGE__->meta->make_immutable;
