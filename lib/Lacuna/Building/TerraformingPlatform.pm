package Lacuna::Building::TerraformingPlatform;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/terraformingplatform';
}

sub model_class {
    return 'Lacuna::DB::Building::Permanent::TerraformingPlatform';
}

no Moose;
__PACKAGE__->meta->make_immutable;

