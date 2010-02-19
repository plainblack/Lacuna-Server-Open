package Lacuna::DB::Building::Food::Farm::Dairy;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Dairy';
}

sub image {
    return 'dairy';
}

sub name {
    return 'Dairy Farm';
}

sub food_to_build {
    return 200;
}

sub energy_to_build {
    return 100;
}

sub ore_to_build {
    return 150;
}

sub water_to_build {
    return 60;
}

sub waste_to_build {
    return 50;
}

sub time_to_build {
    return 80;
}

sub food_consumption {
    return 5;
}

sub milk_production {
    return 47;
}

sub energy_consumption {
    return 8;
}

sub ore_consumption {
    return 3;
}

sub water_consumption {
    return 15;
}

sub waste_production {
    return 48;
}



no Moose;
__PACKAGE__->meta->make_immutable;
