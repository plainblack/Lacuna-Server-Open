package Lacuna::RPC::Building::Shake;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/shake';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Shake';
}

no Moose;
__PACKAGE__->meta->make_immutable;

