package Lacuna::DB::Building::Permanent::GasGiantPlatform;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

sub controller_class {
        return 'Lacuna::Building::GasGiantPlatform';
}

sub image {
    return 'gas-giant-platform';
}

sub check_build_prereqs {
    confess [1013,"You can't directly build a Gas Giant Platform. You need a gas giant platform ship."];
}

sub name {
    return 'Gas Giant Settlement Platform';
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

sub food_consumption {
    return 45;
}

sub energy_consumption {
    return 45;
}

sub ore_consumption {
    return 45;
}

sub water_consumption {
    return 45;
}

sub waste_production {
    return 100;
}

no Moose;
__PACKAGE__->meta->make_immutable;
