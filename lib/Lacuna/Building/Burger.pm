package Lacuna::Building::Burger;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Factory::Burger';
}

no Moose;
__PACKAGE__->meta->make_immutable;

