package Lacuna::DB::Building::Food::Farm::Algae;

use Moose;
extends 'Lacuna::DB::Building::Food::Farm';

sub controller_class {
        return 'Lacuna::Building::Algae';
}

sub image {
    return 'algae';
}

sub name {
    return 'Algae Cropper';
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

sub algae_production {
    return 10;
}

sub energy_production {
    return 3;
}

sub ore_consumption {
    return 1;
}

sub water_consumption {
    return 2;
}

sub waste_consumption {
    return 5;
}

sub waste_production {
    return 6;
}



no Moose;
__PACKAGE__->meta->make_immutable;
