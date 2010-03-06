package Lacuna::DB::Building::Energy::Waste;

use Moose;
extends 'Lacuna::DB::Building::Energy';

sub controller_class {
        return 'Lacuna::Building::WasteEnergy';
}

sub image {
    return 'waste';
}

sub university_prereq {
    return 3;
}

sub name {
    return 'Waste Energy Plant';
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
    return 950;
}

sub food_consumption {
    return 10;
}

sub energy_consumption {
    return 110;
}

sub energy_production {
    return 255;
}

sub ore_consumption {
    return 5;
}

sub water_consumption {
    return 10;
}

sub waste_consumption {
    return 100;
}

sub waste_production {
    return 10;
}



no Moose;
__PACKAGE__->meta->make_immutable;
