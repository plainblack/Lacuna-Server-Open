package Lacuna::Building::Malcud;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Farm::Malcud';
}

no Moose;
__PACKAGE__->meta->make_immutable;

