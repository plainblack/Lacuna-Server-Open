package Lacuna::RPC::Building::Embassy;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/embassy';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Embassy';
}

no Moose;
__PACKAGE__->meta->make_immutable;

