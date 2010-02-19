package Lacuna::DB::Building::Food::Reserve;

use Moose;
extends 'Lacuna::DB::Building::Food';

sub controller_class {
        return 'Lacuna::Building::FoodReserve';
}

sub image {
    return 'food-reserve';
}

sub name {
    return 'Food Reserve';
}

sub food_to_build {
    return 25;
}

sub energy_to_build {
    return 25;
}

sub ore_to_build {
    return 25;
}

sub water_to_build {
    return 25;
}

sub waste_to_build {
    return 25;
}

sub time_to_build {
    return 100;
}

sub food_consumption {
    return 1;
}

sub energy_consumption {
    return 10;
}

sub water_consumption {
    return 1;
}

sub waste_production {
    return 1;
}

sub food_storage {
    return 1500;
}



no Moose;
__PACKAGE__->meta->make_immutable;
