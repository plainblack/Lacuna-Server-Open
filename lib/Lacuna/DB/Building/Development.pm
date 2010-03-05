package Lacuna::DB::Building::Development;

use Moose;
extends 'Lacuna::DB::Building';

sub subsidize_build_queue {
    my ($self, $amount) = @_;
    $self->empire->spend_essentia($amount);
    my $builds = $self->simpledb->domain('build_queue')->search(where=>{body_id=>$self->body_id});
    while (my $build = $builds->next) {
        $build->date_complete->subtract(seconds=>($amount * 600));
        $build->put;
    }
}

sub controller_class {
    return 'Lacuna::Building::Development';
}

sub max_instances_per_planet {
    return 1;
}

sub building_prereq {
    return {'Lacuna::DB::Building::PlanetaryCommand'=>5};
}

sub image {
    return 'development';
}

sub name {
    return 'Development Ministry';
}

sub food_to_build {
    return 70;
}

sub energy_to_build {
    return 70;
}

sub ore_to_build {
    return 70;
}

sub water_to_build {
    return 70;
}

sub waste_to_build {
    return 70;
}

sub time_to_build {
    return 600;
}

sub food_consumption {
    return 25;
}

sub energy_consumption {
    return 50;
}

sub ore_consumption {
    return 10;
}

sub water_consumption {
    return 25;
}

sub waste_production {
    return 5;
}


no Moose;
__PACKAGE__->meta->make_immutable;
