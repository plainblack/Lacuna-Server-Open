package Lacuna::DB::Building::Ore::Refinery;

use Moose;
extends 'Lacuna::DB::Building::Ore';

sub controller_class {
        return 'Lacuna::Building::OreRefinery';
}

sub building_prereq {
    return {'Lacuna::DB::Building::Ore::Mine' => 5};
}

sub max_instances_per_planet {
    return 1;
}

sub university_prereq {
    return 5;
}

sub image {
    return 'orerefinery';
}

sub name {
    return 'Ore Refinery';
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
    return 100;
}

sub time_to_build {
    return 2000;
}

sub food_consumption {
    return 15;
}

sub energy_consumption {
    return 80;
}

sub ore_consumption {
    return 100;
}

sub water_consumption {
    return 100;
}

sub waste_production {
    return 70;
}



no Moose;
__PACKAGE__->meta->make_immutable;
