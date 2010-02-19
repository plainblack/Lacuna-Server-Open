package Lacuna::DB::Building::Park;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::Park';
}

sub image {
    return 'park';
}

sub name {
    return 'Park';
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
    return 100;
}

sub food_consumption {
    return 10;
}

sub energy_consumption {
    return 10;
}

sub ore_consumption {
    return 20;
}

sub water_consumption {
    return 60;
}

sub waste_production {
    return 75;
}

sub happiness_production {
    return 75;
}



no Moose;
__PACKAGE__->meta->make_immutable;
