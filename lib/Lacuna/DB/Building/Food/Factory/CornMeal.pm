package Lacuna::DB::Building::Food::Factory::CornMeal;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::CornMeal';
}

sub image {
    return 'cornmeal';
}

sub min_orbit {
    return 2;
}

sub max_orbit {
    return 3;
}

sub building_prereq {
    return {'Lacuna::DB::Food::Farm::Corn'=>1};
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
