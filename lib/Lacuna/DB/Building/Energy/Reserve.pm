package Lacuna::DB::Building::Energy::Reserve;

use Moose;
extends 'Lacuna::DB::Building::Energy';

sub controller_class {
        return 'Lacuna::Building::EnergyReserve';
}

sub university_prereq {
    return 2;
}

sub image {
    return 'energy-reserve';
}

sub name {
    return 'Energy Reserve';
}

sub food_to_build {
    return 100;
}

sub energy_to_build {
    return 100;
}

sub ore_to_build {
    return 100;
}

sub water_to_build {
    return 100;
}

sub waste_to_build {
    return 200;
}

sub time_to_build {
    return 200;
}

sub food_consumption {
    return 2;
}

sub energy_consumption {
    return 10;
}

sub ore_consumption {
    return 3;
}

sub water_consumption {
    return 1;
}

sub waste_production {
    return 1;
}

sub energy_storage {
    return 1500;
}



no Moose;
__PACKAGE__->meta->make_immutable;
