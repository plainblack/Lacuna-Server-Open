package Lacuna::DB::Building::Security;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
    return 'Lacuna::Building::Security';
}

sub max_instances_per_planet {
    return 1;
}

sub building_prereq {
    return {'Lacuna::DB::Building::Intelligence'=>1};
}

sub image {
    return 'security';
}

sub name {
    return 'Security Ministry';
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
    return 600;
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

sub happiness_consumption {
    return 10;
}


no Moose;
__PACKAGE__->meta->make_immutable;
