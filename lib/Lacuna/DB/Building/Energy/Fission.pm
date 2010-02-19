package Lacuna::DB::Building::Energy::Fission;

use Moose;
extends 'Lacuna::DB::Building::Energy';

sub controller_class {
        return 'Lacuna::Building::Fission';
}

sub image {
    return 'fission';
}

sub name {
    return 'Fission Energy Plant';
}

sub food_to_build {
    return 100;
}

sub energy_to_build {
    return 200;
}

sub ore_to_build {
    return 200;
}

sub water_to_build {
    return 150;
}

sub waste_to_build {
    return 75;
}

sub time_to_build {
    return 155;
}

sub food_consumption {
    return 5;
}

sub energy_consumption {
    return 70;
}

sub energy_production {
    return 450;
}

sub ore_consumption {
    return 35;
}

sub water_consumption {
    return 50;
}

sub waste_production {
    return 70;
}



no Moose;
__PACKAGE__->meta->make_immutable;
