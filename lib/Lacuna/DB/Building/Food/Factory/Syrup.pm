package Lacuna::DB::Building::Food::Factory::Syrup;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Syrup';
}

sub image {
    return 'syrup';
}

sub building_prereq {
    return {'Lacuna::DB::Food::Farm::Algae'=>1};
}

sub name {
    return 'Algae Syrup Bottler';
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
    return 150;
}

sub syrup_production {
    return 100;
}

sub energy_consumption {
    return 75;
}

sub water_consumption {
    return 25;
}

sub waste_production {
    return 75;
}



no Moose;
__PACKAGE__->meta->make_immutable;
