package Lacuna::Building::Pancake;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Factory::Pancake';
}

no Moose;
__PACKAGE__->meta->make_immutable;

