package Lacuna::DB::Building::Food::Farm::Beeldeban;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Beeldeban';
}

sub image {
    return 'beeldeban';
}

sub name {
    return 'Beeldeban Herder';
}

sub food_to_build {
    return 100;
}

sub energy_to_build {
    return 100;
}

sub ore_to_build {
    return 125;
}

sub water_to_build {
    return 50;
}

sub waste_to_build {
    return 35;
}

sub time_to_build {
    return 80;
}

sub food_consumption {
    return 5;
}

sub beetle_production {
    return 35;
}

sub energy_consumption {
    return 2;
}

sub ore_consumption {
    return 4;
}

sub water_consumption {
    return 3;
}

sub waste_production {
    return 23;
}

sub waste_consumption {
    return 15;
}



no Moose;
__PACKAGE__->meta->make_immutable;
