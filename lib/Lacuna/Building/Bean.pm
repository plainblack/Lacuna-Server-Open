package Lacuna::Building::Bean;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Farm::Bean';
}

no Moose;
__PACKAGE__->meta->make_immutable;

