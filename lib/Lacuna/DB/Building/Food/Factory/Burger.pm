package Lacuna::DB::Building::Food::Factory::Burger;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Burger';
}

sub image {
    return 'burger';
}

sub name {
    return 'Malcud Burger Packer';
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

sub burger_production {
    return 100;
}

sub energy_consumption {
    return 40;
}

sub ore_consumption {
    return 1;
}

sub water_consumption {
    return 10;
}

sub waste_production {
    return 25;
}



no Moose;
__PACKAGE__->meta->make_immutable;
