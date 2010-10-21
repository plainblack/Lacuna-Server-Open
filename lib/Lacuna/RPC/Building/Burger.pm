package Lacuna::RPC::Building::Burger;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/burger';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Burger';
}

no Moose;
__PACKAGE__->meta->make_immutable;

