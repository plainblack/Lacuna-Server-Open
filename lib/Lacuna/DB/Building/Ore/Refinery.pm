package Lacuna::DB::Building::Ore::Refinery;

use Moose;
extends 'Lacuna::DB::Building::Ore';

sub controller_class {
        return 'Lacuna::Building::OreRefinery';
}

sub image {
    return 'refinery';
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
    return 200;
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
