package Lacuna::Building::Apple;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Farm::Apple';
}

no Moose;
__PACKAGE__->meta->make_immutable;

