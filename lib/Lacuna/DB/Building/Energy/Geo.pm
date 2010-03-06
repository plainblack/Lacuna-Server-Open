package Lacuna::DB::Building::Energy::Geo;

use Moose;
extends 'Lacuna::DB::Building::Energy';

sub controller_class {
        return 'Lacuna::Building::Geo';
}

sub image {
    return 'geo';
}

sub name {
    return 'Geo Energy Plant';
}

sub food_to_build {
    return 100;
}

sub energy_to_build {
    return 10;
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
    return 1300;
}

sub food_consumption {
    return 2;
}

sub energy_consumption {
    return 40;
}

sub energy_production {
    return 141;
}

sub ore_consumption {
    return 12;
}

sub water_consumption {
    return 7;
}

sub waste_production {
    return 4;
}



no Moose;
__PACKAGE__->meta->make_immutable;
