package Lacuna::DB::Building::RND;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::RND';
}

sub image {
    return 'rnd';
}

sub name {
    return 'Research and Development Lab';
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
    return 120;
}

sub food_consumption {
    return 10;
}

sub energy_consumption {
    return 25;
}

sub ore_consumption {
    return 25;
}

sub water_consumption {
    return 10;
}

sub waste_production {
    return 15;
}

sub happiness_production {
    return 50;
}



no Moose;
__PACKAGE__->meta->make_immutable;
