package Lacuna::DB::Building::Water::Storage;

use Moose;
extends 'Lacuna::DB::Building::Water';

sub controller_class {
        return 'Lacuna::Building::WaterStorage';
}

sub image {
    return 'water-storage';
}

sub name {
    return 'Water Storage';
}

sub food_to_build {
    return 25;
}

sub energy_to_build {
    return 25;
}

sub ore_to_build {
    return 25;
}

sub water_to_build {
    return 25;
}

sub waste_to_build {
    return 25;
}

sub time_to_build {
    return 100;
}

sub food_consumption {
    return 2;
}

sub energy_consumption {
    return 5;
}

sub ore_consumption {
    return 5;
}

sub water_consumption {
    return 1;
}

sub waste_production {
    return 1;
}

sub water_storage {
    return 1500;
}



no Moose;
__PACKAGE__->meta->make_immutable;
