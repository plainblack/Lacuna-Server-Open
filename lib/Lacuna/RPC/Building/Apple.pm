package Lacuna::RPC::Building::Apple;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/apple';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Apple';
}

no Moose;
__PACKAGE__->meta->make_immutable;

