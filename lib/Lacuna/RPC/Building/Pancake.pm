package Lacuna::RPC::Building::Pancake;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/pancake';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Pancake';
}

no Moose;
__PACKAGE__->meta->make_immutable;

