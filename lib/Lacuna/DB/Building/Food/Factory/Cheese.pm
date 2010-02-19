package Lacuna::DB::Building::Food::Factory::Cheese;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Cheese';
}

sub image {
    return 'cheese';
}

sub name {
    return 'Cheese Maker';
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

sub cheese_production {
    return 100;
}

sub energy_consumption {
    return 75;
}

sub ore_consumption {
    return 2;
}

sub water_consumption {
    return 75;
}

sub waste_production {
    return 125;
}



no Moose;
__PACKAGE__->meta->make_immutable;
