package Lacuna::RPC::Building::Potato;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/potato';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Potato';
}

no Moose;
__PACKAGE__->meta->make_immutable;

