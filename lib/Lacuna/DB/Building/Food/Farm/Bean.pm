package Lacuna::DB::Building::Food::Farm::Bean;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Bean';
}

sub min_orbit {
    return 4;
}

sub max_orbit {
    return 4;
}

sub image {
    return 'bean';
}

sub name {
    return 'Amalgus Bean Plantation';
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
    return 600;
}

sub food_consumption {
    return 5;
}

sub bean_production {
    return 60;
}

sub energy_consumption {
    return 1;
}

sub ore_consumption {
    return 10;
}

sub water_consumption {
    return 7;
}

sub waste_production {
    return 10;
}



no Moose;
__PACKAGE__->meta->make_immutable;
