package Lacuna::Building::Cheese;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Factory::Cheese';
}

no Moose;
__PACKAGE__->meta->make_immutable;

