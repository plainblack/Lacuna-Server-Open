package Lacuna::RPC::Building::Malcud;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/malcud';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Malcud';
}

no Moose;
__PACKAGE__->meta->make_immutable;

