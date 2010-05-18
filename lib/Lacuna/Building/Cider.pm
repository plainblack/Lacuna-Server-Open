package Lacuna::RPC::Building::Cider;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/cider';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Cider';
}

no Moose;
__PACKAGE__->meta->make_immutable;

