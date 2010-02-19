package Lacuna::DB::Building::Ore::Mine;

use Moose;
extends 'Lacuna::DB::Building::Ore';

sub controller_class {
        return 'Lacuna::Building::Mine';
}

sub image {
    return 'mine';
}

sub name {
    return 'Mine';
}

sub food_to_build {
    return 100;
}

sub energy_to_build {
    return 100;
}

sub ore_to_build {
    return 10;
}

sub water_to_build {
    return 100;
}

sub waste_to_build {
    return 85;
}

sub time_to_build {
    return 100;
}

sub food_consumption {
    return 10;
}

sub energy_consumption {
    return 10;
}

sub ore_production {
    return 125;
}

sub water_consumption {
    return 10;
}

sub waste_production {
    return 25;
}



no Moose;
__PACKAGE__->meta->make_immutable;
