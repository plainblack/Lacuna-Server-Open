package Lacuna::Building::Lake;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Permanent::Lake';
}

no Moose;
__PACKAGE__->meta->make_immutable;

