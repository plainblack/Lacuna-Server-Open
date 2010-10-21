package Lacuna::RPC::Building::Wheat;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/wheat';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Wheat';
}

no Moose;
__PACKAGE__->meta->make_immutable;

