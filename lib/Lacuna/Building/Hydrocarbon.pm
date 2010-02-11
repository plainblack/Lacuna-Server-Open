package Lacuna::Building::Hydrocarbon;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/hydrocarbon';
}

sub model_class {
    return 'Lacuna::DB::Building::Energy::Hydrocarbon';
}

no Moose;
__PACKAGE__->meta->make_immutable;

