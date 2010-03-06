package Lacuna::DB::Building::Water::Purification;

use Moose;
extends 'Lacuna::DB::Building::Water';

sub controller_class {
    return 'Lacuna::Building::WaterPurification';
}

sub image {
    return 'purification';
}

sub name {
    return 'Water Purification Plant';
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
    return 20;
}

sub time_to_build {
    return 850;
}

sub food_consumption {
    return 5;
}

sub energy_consumption {
    return 15;
}

sub ore_consumption {
    return 15;
}

sub water_production {
    return 100;
}

sub water_production_hour {
    my ($self) = @_;
    return sprintf('%.0f',$self->body->water * $self->water_production * $self->production_hour / 10000);
}

sub waste_production {
    return 10;
}



no Moose;
__PACKAGE__->meta->make_immutable;
