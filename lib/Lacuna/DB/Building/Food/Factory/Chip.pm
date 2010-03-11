package Lacuna::DB::Building::Food::Factory::Chip;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Chip';
}

sub image {
    return 'chips';
}

sub min_orbit {
    return 5;
}

sub max_orbit {
    return 5;
}

sub building_prereq {
    return {'Lacuna::DB::Building::Food::Farm::Root'=>1};
}

sub name {
    return 'Denton Root Chip Frier';
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

sub chip_production {
    return 100;
}

sub energy_consumption {
    return 25;
}

sub ore_consumption {
    return 25;
}

sub water_consumption {
    return 25;
}

sub waste_production {
    return 50;
}



no Moose;
__PACKAGE__->meta->make_immutable;
