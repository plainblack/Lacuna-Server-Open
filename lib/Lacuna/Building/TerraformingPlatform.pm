package Lacuna::RPC::Building::TerraformingPlatform;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/terraformingplatform';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform';
}

no Moose;
__PACKAGE__->meta->make_immutable;

