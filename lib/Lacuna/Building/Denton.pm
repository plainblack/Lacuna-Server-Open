package Lacuna::Building::Denton;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Farm::Root';
}

no Moose;
__PACKAGE__->meta->make_immutable;

