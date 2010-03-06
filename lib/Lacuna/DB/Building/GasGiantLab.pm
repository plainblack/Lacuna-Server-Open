package Lacuna::DB::Building::GasGiantLab;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
    return 'Lacuna::Building::GasGiantLab';
}

sub university_prereq {
    return 17;
}

sub image {
    return 'gas-giant-lab';
}

sub name {
    return 'Gas Giant Lab';
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
    return 9000;
}

sub food_consumption {
    return 50;
}

sub energy_consumption {
    return 50;
}

sub ore_consumption {
    return 50;
}

sub water_consumption {
    return 50;
}

sub waste_production {
    return 100;
}


no Moose;
__PACKAGE__->meta->make_immutable;
