package Lacuna::RPC::Building::Geo;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/geo';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Energy::Geo';
}

no Moose;
__PACKAGE__->meta->make_immutable;

