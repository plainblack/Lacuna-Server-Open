package Lacuna::RPC::Building::Dairy;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/dairy';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Dairy';
}

no Moose;
__PACKAGE__->meta->make_immutable;

