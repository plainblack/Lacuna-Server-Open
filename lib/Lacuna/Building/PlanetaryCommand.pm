package Lacuna::Building::PlanetaryCommand;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::PlanetaryCommand';
}

no Moose;
__PACKAGE__->meta->make_immutable;

