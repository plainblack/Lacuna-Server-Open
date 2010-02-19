package Lacuna::DB::Building::Food::Farm::Apple;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Apple';
}

sub image {
    return 'apple';
}

sub name {
    return 'Apple Orchard';
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
    return 5;
}

sub time_to_build {
    return 60;
}

sub food_consumption {
    return 5;
}

sub apple_production {
    return 46;
}

sub energy_consumption {
    return 1;
}

sub ore_consumption {
    return 1;
}

sub water_consumption {
    return 9;
}

sub waste_production {
    return 16;
}

sub waste_consumption {
    return 3;
}



no Moose;
__PACKAGE__->meta->make_immutable;
