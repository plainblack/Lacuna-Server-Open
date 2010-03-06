package Lacuna::DB::Building::Shipyard;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::Shipyard';
}

sub building_prereq {
    return {'Lacuna::DB::Building::SpacePort'=>1};
}

sub image {
    return 'shipyard';
}

sub name {
    return 'Shipyard';
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
    return 100;
}

sub waste_to_build {
    return 100;
}

sub time_to_build {
    return 1200;
}

sub food_consumption {
    return 5;
}

sub energy_consumption {
    return 10;
}

sub ore_consumption {
    return 5;
}

sub water_consumption {
    return 7;
}

sub waste_production {
    return 2;
}


no Moose;
__PACKAGE__->meta->make_immutable;
