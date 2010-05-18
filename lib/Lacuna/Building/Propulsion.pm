package Lacuna::RPC::Building::Propulsion;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/propulsion';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Propulsion';
}

no Moose;
__PACKAGE__->meta->make_immutable;

