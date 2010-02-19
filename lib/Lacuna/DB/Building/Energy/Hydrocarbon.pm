package Lacuna::DB::Building::Energy::Hydrocarbon;

use Moose;
extends 'Lacuna::DB::Building::Energy';

sub controller_class {
        return 'Lacuna::Building::Hydrocarbon';
}

sub image {
    return 'hydrocarbon';
}

sub name {
    return 'Hydrocarbon Energy Plant';
}

sub food_to_build {
    return 100;
}

sub energy_to_build {
    return 10;
}

sub ore_to_build {
    return 100;
}

sub water_to_build {
    return 100;
}

sub waste_to_build {
    return 20;
}

sub time_to_build {
    return 70;
}

sub food_consumption {
    return 15;
}

sub energy_consumption {
    return 120;
}

sub energy_production {
    return 490;
}

sub ore_consumption {
    return 90;
}

sub water_consumption {
    return 15;
}

sub waste_production {
    return 230;
}



no Moose;
__PACKAGE__->meta->make_immutable;
