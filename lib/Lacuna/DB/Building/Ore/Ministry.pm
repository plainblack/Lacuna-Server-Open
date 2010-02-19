package Lacuna::DB::Building::Ore::Minestry;

use Moose;
extends 'Lacuna::DB::Building::Ore';

sub controller_class {
        return 'Lacuna::Building::MiningMinistry';
}

sub image {
    return 'mining-ministry';
}

sub name {
    return 'Mining Ministry';
}

sub food_to_build {
    return 70;
}

sub energy_to_build {
    return 70;
}

sub ore_to_build {
    return 70;
}

sub water_to_build {
    return 70;
}

sub waste_to_build {
    return 70;
}

sub time_to_build {
    return 60;
}

sub food_consumption {
    return 25;
}

sub energy_consumption {
    return 50;
}

sub ore_consumption {
    return 10;
}

sub water_consumption {
    return 35;
}

sub waste_production {
    return 5;
}


no Moose;
__PACKAGE__->meta->make_immutable;
