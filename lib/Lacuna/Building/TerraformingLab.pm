package Lacuna::Building::TerraformingLab;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/terraforminglab';
}

sub model_class {
    return 'Lacuna::DB::Building::TerraformingLab';
}

no Moose;
__PACKAGE__->meta->make_immutable;

