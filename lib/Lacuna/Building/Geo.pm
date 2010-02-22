package Lacuna::Building::Geo;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/geo';
}

sub model_class {
    return 'Lacuna::DB::Building::Energy::Geo';
}

no Moose;
__PACKAGE__->meta->make_immutable;

