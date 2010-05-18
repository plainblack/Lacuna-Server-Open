package Lacuna::RPC::Building::RND;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/rnd';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::RND';
}

no Moose;
__PACKAGE__->meta->make_immutable;

