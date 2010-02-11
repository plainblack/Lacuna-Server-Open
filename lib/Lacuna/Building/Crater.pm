package Lacuna::Building::Crater;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/crater';
}

sub model_class {
    return 'Lacuna::DB::Building::Permanent::Crater';
}

no Moose;
__PACKAGE__->meta->make_immutable;

