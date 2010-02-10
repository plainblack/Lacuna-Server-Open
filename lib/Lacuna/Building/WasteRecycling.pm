package Lacuna::Building::WasteRecycling;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Waste::Recycling';
}

no Moose;
__PACKAGE__->meta->make_immutable;

