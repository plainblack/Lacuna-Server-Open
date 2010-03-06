package Lacuna::DB::Building::Waste::Recycling;

use Moose;
extends 'Lacuna::DB::Building::Waste';

sub controller_class {
        return 'Lacuna::Building::WasteRecycling';
}

sub image {
    return 'recycling';
}

sub university_prereq {
    return 3;
}

sub name {
    return 'Waste Recycling Center';
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
    return 20;
}

sub time_to_build {
    return 950;
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
    return 5;
}

sub waste_consumption {
    return 5;
}



no Moose;
__PACKAGE__->meta->make_immutable;
