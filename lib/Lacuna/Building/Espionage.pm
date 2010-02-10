package Lacuna::Building::Espionage;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Espionage';
}

no Moose;
__PACKAGE__->meta->make_immutable;

