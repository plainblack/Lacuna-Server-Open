package Lacuna::Building::Wheat;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Farm::Wheat';
}

no Moose;
__PACKAGE__->meta->make_immutable;

