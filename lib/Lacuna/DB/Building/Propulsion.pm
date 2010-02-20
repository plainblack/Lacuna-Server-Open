package Lacuna::DB::Building::Propulsion;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::Propulsion';
}

sub building_prereq {
    return {'Lacuna::DB::Building::Shipyard'=>1};
}

sub max_instances_per_planet {
    return 1;
}

sub image {
    return 'propulsion';
}

sub name {
    return 'Propulsion System Factory';
}

sub food_to_build {
    return 150;
}

sub energy_to_build {
    return 225;
}

sub ore_to_build {
    return 225;
}

sub water_to_build {
    return 100;
}

sub waste_to_build {
    return 150;
}

sub time_to_build {
    return 125;
}

sub food_consumption {
    return 10;
}

sub energy_consumption {
    return 100;
}

sub ore_consumption {
    return 100;
}

sub water_consumption {
    return 50;
}

sub waste_production {
    return 75;
}


no Moose;
__PACKAGE__->meta->make_immutable;
