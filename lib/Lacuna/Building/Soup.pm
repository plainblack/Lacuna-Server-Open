package Lacuna::RPC::Building::Soup;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/soup';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Soup';
}

no Moose;
__PACKAGE__->meta->make_immutable;

