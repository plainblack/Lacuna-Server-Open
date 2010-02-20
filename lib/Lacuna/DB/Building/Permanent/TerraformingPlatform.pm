package Lacuna::DB::Building::Permanent::TerraformingPlatform;

use Moose;
extends 'Lacuna::DB::Building::Permanent';

sub controller_class {
        return 'Lacuna::Building::TerraformingPlatform';
}

sub check_build_prereqs {
    confess [1013,"You can't directly build a Terraforming Platform. You need a terraforming platform ship."];
}

sub image {
    return 'terraforming-platform';
}

sub name {
    return 'Terraforming Platform';
}

sub food_to_build {
    return 1000;
}

sub energy_to_build {
    return 1000;
}

sub ore_to_build {
    return 1000;
}

sub water_to_build {
    return 1000;
}

sub waste_to_build {
    return 1000;
}

sub time_to_build {
    return 600;
}

sub food_consumption {
    return 45;
}

sub energy_consumption {
    return 45;
}

sub ore_consumption {
    return 45;
}

sub water_consumption {
    return 45;
}

sub waste_production {
    return 100;
}

no Moose;
__PACKAGE__->meta->make_immutable;
