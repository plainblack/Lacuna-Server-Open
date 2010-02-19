package Lacuna::DB::Building::Observatory;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::Observatory';
}

sub image {
    return 'observatory';
}

sub name {
    return 'Observatory';
}

sub food_to_build {
    return 150;
}

sub energy_to_build {
    return 150;
}

sub ore_to_build {
    return 150;
}

sub water_to_build {
    return 150;
}

sub waste_to_build {
    return 150;
}

sub time_to_build {
    return 250;
}

sub food_consumption {
    return 5;
}

has '+energy_consumption' => (
    default => -50,
);

sub ore_consumption {
    return 5;
}

sub water_consumption {
    return 15;
}

sub waste_production {
    return 2;
}


no Moose;
__PACKAGE__->meta->make_immutable;
