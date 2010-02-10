package Lacuna::Building::Beeldeban;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Farm::Beeldeban';
}

no Moose;
__PACKAGE__->meta->make_immutable;

