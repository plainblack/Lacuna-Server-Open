package Lacuna::RPC::Building::Oversight;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/oversight';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Oversight';
}

no Moose;
__PACKAGE__->meta->make_immutable;

