package Lacuna::DB::Building::Transporter;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
    return 'Lacuna::Building::Transporter';
}

sub university_prereq {
    return 12;
}

sub image {
    return 'transporter';
}

sub name {
    return 'Subspace Transporter';
}

sub food_to_build {
    return 1200;
}

sub energy_to_build {
    return 1400;
}

sub ore_to_build {
    return 1500;
}

sub water_to_build {
    return 1200;
}

sub waste_to_build {
    return 900;
}

sub time_to_build {
    return 11500;
}

sub food_consumption {
    return 5;
}

sub energy_consumption {
    return 20;
}

sub ore_consumption {
    return 13;
}

sub water_consumption {
    return 20;
}

sub waste_production {
    return 2;
}


no Moose;
__PACKAGE__->meta->make_immutable;
