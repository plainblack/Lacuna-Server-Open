package Lacuna::DB::Building::PlanetaryCommand;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::PlanetaryCommand';
}

sub check_build_prereqs {
    confess [1013,"You can't directly build a Planetary Command. You need a colony ship."];
}

sub image {
    return 'command';
}

sub name {
    return 'Planetary Command';
}

sub food_to_build {
    return 1000;
}

sub energy_to_build {
    return 1000;
}

sub ore_to_build {
    return 1000;
}

sub water_to_build {
    return 1000;
}

sub waste_to_build {
    return 1000;
}

sub time_to_build {
    return 600;
}

sub algae_production {
    return 100;
}

sub energy_production {
    return 100;
}

sub ore_production {
    return 100;
}

sub water_production {
    return 100;
}

sub waste_production {
    return 10;
}

sub food_storage {
    return 300;
}

sub energy_storage {
    return 300;
}

sub ore_storage {
    return 300;
}

sub water_storage {
    return 300;
}

sub waste_storage {
    return 300;
}



no Moose;
__PACKAGE__->meta->make_immutable;
