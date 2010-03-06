package Lacuna::DB::Building::TerraformingLab;

use Moose;
extends 'Lacuna::DB::Building';

sub controller_class {
        return 'Lacuna::Building::TerraformingLab';
}

sub university_prereq {
    return 9;
}

sub image {
    return 'terraforming-lab';
}

sub name {
    return 'Terraforming Lab';
}

sub food_to_build {
    return 250;
}

sub energy_to_build {
    return 250;
}

sub ore_to_build {
    return 500;
}

sub water_to_build {
    return 100;
}

sub waste_to_build {
    return 250;
}

sub time_to_build {
    return 9000;
}

sub food_consumption {
    return 50;
}

sub energy_consumption {
    return 50;
}

sub ore_consumption {
    return 50;
}

sub water_consumption {
    return 50;
}

sub waste_production {
    return 100;
}


no Moose;
__PACKAGE__->meta->make_immutable;
