package Lacuna::Building::Chip;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Food::Factory::Chip';
}

no Moose;
__PACKAGE__->meta->make_immutable;

