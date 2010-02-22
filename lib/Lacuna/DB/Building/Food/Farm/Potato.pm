package Lacuna::DB::Building::Food::Farm::Potato;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
    return 'Lacuna::Building::Potato';
}

sub min_orbit {
    return 3;
}

sub max_orbit {
    return 4;
}

sub image {
    return 'potato';
}

sub name {
    return 'Potato Patch';
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
    return 10;
}

sub time_to_build {
    return 60;
}

sub food_consumption {
    return 5;
}

sub potato_production {
    return 62;
}

sub energy_consumption {
    return 1;
}

sub ore_consumption {
    return 2;
}

sub water_consumption {
    return 10;
}

sub waste_production {
    return 8;
}



no Moose;
__PACKAGE__->meta->make_immutable;
