package Lacuna::Building::Corn;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Farm::Corn';
}

no Moose;
__PACKAGE__->meta->make_immutable;

