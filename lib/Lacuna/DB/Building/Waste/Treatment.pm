package Lacuna::DB::Building::Waste::Treatment;

use Moose;
extends 'Lacuna::DB::Building::Waste';

sub controller_class {
        return 'Lacuna::Building::WasteTreatment';
}

sub image {
    return 'waste-treatment';
}

sub name {
    return 'Waste Treatment Center';
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
    return 95;
}

sub food_consumption {
    return 5;
}

sub energy_consumption {
    return 10;
}

sub energy_production {
    return 30;
}

sub ore_consumption {
    return 10;
}

sub ore_production {
    return 30;
}

sub water_consumption {
    return 10;
}

sub water_production {
    return 30;
}

sub waste_consumption {
    return 110;
}

sub waste_production {
    return 10;
}



no Moose;
__PACKAGE__->meta->make_immutable;
