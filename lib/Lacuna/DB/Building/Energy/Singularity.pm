package Lacuna::DB::Building::Energy::Singularity;

use Moose;
extends 'Lacuna::DB::Building::Energy';

sub controller_class {
        return 'Lacuna::Building::Singularity';
}

sub image {
    return 'singularity';
}

sub university_prereq {
    return 17;
}

sub name {
    return 'Singularity Energy Plant';
}

sub food_to_build {
    return 1100;
}

sub energy_to_build {
    return 1205;
}

sub ore_to_build {
    return 2350;
}

sub water_to_build {
    return 1190;
}

sub waste_to_build {
    return 1475;
}

sub time_to_build {
    return 1300;
}

sub food_consumption {
    return 27;
}

sub energy_consumption {
    return 350;
}

sub energy_production {
    return 799;
}

sub ore_consumption {
    return 23;
}

sub water_consumption {
    return 25;
}

sub waste_production {
    return 1;
}



no Moose;
__PACKAGE__->meta->make_immutable;
