package Lacuna::DB::Building::Food::Farm::Malcud;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Malcud';
}

sub image {
    return 'malcud';
}

sub name {
    return 'Malcud Fungus Farm';
}

sub food_to_build {
    return 10;
}

sub energy_to_build {
    return 100;
}

sub ore_to_build {
    return 55;
}

sub water_to_build {
    return 30;
}

sub waste_to_build {
    return 20;
}

sub time_to_build {
    return 60;
}

sub food_consumption {
    return 5;
}

sub fungus_production {
    return 31;
}

sub energy_consumption {
    return 1;
}

sub ore_production {
    return 4;
}

sub water_consumption {
    return 4;
}

sub waste_consumption {
    return 1;
}



no Moose;
__PACKAGE__->meta->make_immutable;
