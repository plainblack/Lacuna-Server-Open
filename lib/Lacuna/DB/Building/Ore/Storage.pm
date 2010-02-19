package Lacuna::DB::Building::Ore::Storage;

use Moose;
extends 'Lacuna::DB::Building::Ore';

sub controller_class {
        return 'Lacuna::Building::OreStorage';
}

sub image {
    return 'storage-tanks';
}

sub name {
    return 'Storage Tanks';
}

sub food_to_build {
    return 10;
}

sub energy_to_build {
    return 10;
}

sub ore_to_build {
    return 10;
}

sub water_to_build {
    return 10;
}

sub waste_to_build {
    return 25;
}

sub time_to_build {
    return 100;
}


no Moose;
__PACKAGE__->meta->make_immutable;
