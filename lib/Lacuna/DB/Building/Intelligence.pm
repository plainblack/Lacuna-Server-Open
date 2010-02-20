package Lacuna::DB::Building::Intelligence;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::Intelligence';
}

sub max_instances_per_planet {
    return 1;
}

sub building_prereq {
    return {'Lacuna::DB::Building::PlanetaryCommand'=>5,'Lacuna::DB::Building::Shipyard'=>1};
}

sub image {
    return 'intelligence';
}

sub name {
    return 'Intelligence Ministry';
}

sub food_to_build {
    return 70;
}

sub energy_to_build {
    return 70;
}

sub ore_to_build {
    return 70;
}

sub water_to_build {
    return 70;
}

sub waste_to_build {
    return 70;
}

sub time_to_build {
    return 60;
}

sub food_consumption {
    return 25;
}

sub energy_consumption {
    return 50;
}

sub ore_consumption {
    return 10;
}

sub water_consumption {
    return 35;
}

sub waste_production {
    return 5;
}


no Moose;
__PACKAGE__->meta->make_immutable;
