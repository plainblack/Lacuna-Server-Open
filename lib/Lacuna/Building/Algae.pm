package Lacuna::Building::Algae;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Farm::Algae';
}

no Moose;
__PACKAGE__->meta->make_immutable;

