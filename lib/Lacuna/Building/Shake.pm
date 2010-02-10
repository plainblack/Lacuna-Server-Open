package Lacuna::Building::Shake;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Factory::Shake';
}

no Moose;
__PACKAGE__->meta->make_immutable;

