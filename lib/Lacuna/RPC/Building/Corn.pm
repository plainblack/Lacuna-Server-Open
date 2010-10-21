package Lacuna::RPC::Building::Corn;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/corn';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Corn';
}

no Moose;
__PACKAGE__->meta->make_immutable;

