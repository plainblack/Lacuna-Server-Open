package Lacuna::Building::GasGiantPlatform;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/gasgiantplatform';
}

sub model_class {
    return 'Lacuna::DB::Building::Permanent::GasGiantPlatform';
}

no Moose;
__PACKAGE__->meta->make_immutable;

