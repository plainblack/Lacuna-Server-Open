package Lacuna::Building::SpacePort;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::SpacePort';
}

no Moose;
__PACKAGE__->meta->make_immutable;

