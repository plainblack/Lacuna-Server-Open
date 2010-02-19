package Lacuna::DB::Building::Food::Farm::Wheat;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Wheat';
}

sub image {
    return 'wheat';
}

sub name {
    return 'Wheat Farm';
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

sub wheat_production {
    return 38;
}

sub energy_consumption {
    return 1;
}

sub ore_consumption {
    return 1;
}

sub water_consumption {
    return 10;
}

sub waste_production {
    return 28;
}



no Moose;
__PACKAGE__->meta->make_immutable;
