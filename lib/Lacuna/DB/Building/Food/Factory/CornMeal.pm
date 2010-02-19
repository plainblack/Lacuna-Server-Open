package Lacuna::DB::Building::Food::Factory::CornMeal;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::CornMeal';
}

sub image {
    return 'cornmeal';
}

sub name {
    return 'Corn Meal Grinder';
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

sub meal_production {
    return 125;
}

sub energy_consumption {
    return 50;
}

sub water_consumption {
    return 25;
}

sub waste_production {
    return 50;
}



no Moose;
__PACKAGE__->meta->make_immutable;
