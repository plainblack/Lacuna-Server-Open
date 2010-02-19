package Lacuna::DB::Building::EntertainmentDistrict;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::Entertainment';
}

sub image {
    return 'entertainment';
}

sub name {
    return 'Entertainment District';
}

sub food_to_build {
    return 500;
}

sub energy_to_build {
    return 500;
}

sub ore_to_build {
    return 800;
}

sub water_to_build {
    return 500;
}

sub waste_to_build {
    return 500;
}

sub time_to_build {
    return 250;
}

sub food_consumption {
    return 100;
}

sub energy_consumption {
    return 100;
}

sub ore_consumption {
    return 10;
}

sub water_consumption {
    return 100;
}

sub waste_production {
    return 300;
}

sub happiness_production {
    return 200;
}



no Moose;
__PACKAGE__->meta->make_immutable;
