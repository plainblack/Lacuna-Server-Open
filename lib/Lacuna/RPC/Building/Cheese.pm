package Lacuna::RPC::Building::Cheese;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/cheese';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Cheese';
}

no Moose;
__PACKAGE__->meta->make_immutable;

