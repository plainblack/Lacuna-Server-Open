package Lacuna::DB::Building::Food::Factory::Soup;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Soup';
}

sub image {
    return 'soup';
}

sub name {
    return 'Amalgus Bean Soup Cannery';
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

sub soup_production {
    return 110;
}

sub energy_consumption {
    return 20;
}

sub ore_consumption {
    return 3;
}

sub water_consumption {
    return 30;
}

sub waste_production {
    return 25;
}



no Moose;
__PACKAGE__->meta->make_immutable;
