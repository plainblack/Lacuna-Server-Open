package Lacuna::DB::Building::University;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::University';
}

sub image {
    return 'university';
}

sub name {
    return 'University';
}

sub food_to_build {
    return 250;
}

sub energy_to_build {
    return 500;
}

sub ore_to_build {
    return 500;
}

sub water_to_build {
    return 100;
}

sub waste_to_build {
    return 250;
}

sub time_to_build {
    return 130;
}

sub food_consumption {
    return 50;
}

sub energy_consumption {
    return 50;
}

sub ore_consumption {
    return 10;
}

sub water_consumption {
    return 50;
}

sub waste_production {
    return 50;
}

sub happiness_production {
    return 50;
}



no Moose;
__PACKAGE__->meta->make_immutable;
