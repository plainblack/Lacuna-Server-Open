package Lacuna::DB::Building::Food::Factory::Pie;

use Moose;
extends 'Lacuna::DB::Building::Food::Factory';

sub controller_class {
        return 'Lacuna::Building::Pie';
}

sub image {
    return 'pie';
}

sub min_orbit {
    return 2;
}

sub max_orbit {
    return 2;
}

sub building_prereq {
    return {'Lacuna::DB::Building::Food::Farm::Lapis'=>1};
}

sub name {
    return 'Lapis Pie Bakery';
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
    return 2000;
}

sub food_consumption {
    return 150;
}

sub pie_production {
    return 100;
}

sub energy_consumption {
    return 50;
}

sub water_consumption {
    return 20;
}

sub waste_production {
    return 50;
}



no Moose;
__PACKAGE__->meta->make_immutable;
