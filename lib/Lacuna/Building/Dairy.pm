package Lacuna::Building::Dairy;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Farm::Dairy';
}

no Moose;
__PACKAGE__->meta->make_immutable;

