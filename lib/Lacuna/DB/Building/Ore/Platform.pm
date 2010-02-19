package Lacuna::DB::Building::Ore::Platform;

use Moose;
extends 'Lacuna::DB::Building::Ore';

sub controller_class {
        return 'Lacuna::Building::MiningPlatform';
}

sub image {
    return 'mining-platform';
}

sub name {
    return 'Mining Platform';
}

sub food_to_build {
    return 500;
}

sub energy_to_build {
    return 500;
}

sub ore_to_build {
    return 50;
}

sub water_to_build {
    return 500;
}

sub waste_to_build {
    return 425;
}

sub time_to_build {
    return 500;
}

sub food_consumption {
    return 10;
}

sub energy_consumption {
    return 50;
}

sub ore_production {
    return 280;
}

sub water_consumption {
    return 50;
}

sub waste_production {
    return 50;
}


no Moose;
__PACKAGE__->meta->make_immutable;

