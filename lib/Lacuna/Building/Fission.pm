package Lacuna::Building::Fission;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::Energy::Fission';
}

no Moose;
__PACKAGE__->meta->make_immutable;

