package Lacuna::DB::Building::Waste::Sequestration;

use Moose;
extends 'Lacuna::DB::Building::Waste';

sub controller_class {
        return 'Lacuna::Building::WasteSequestration';
}

sub image {
    return 'sequestration';
}

sub name {
    return 'Waste Sequestration Well';
}

sub food_to_build {
    return 10;
}

sub energy_to_build {
    return 10;
}

sub ore_to_build {
    return 10;
}

sub water_to_build {
    return 10;
}

sub waste_to_build {
    return 25;
}

sub time_to_build {
    return 1000;
}

sub waste_storage {
    return 1500;
}



no Moose;
__PACKAGE__->meta->make_immutable;
