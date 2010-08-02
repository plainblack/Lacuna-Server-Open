package Lacuna::RPC::Building::Bread;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/bread';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Bread';
}

no Moose;
__PACKAGE__->meta->make_immutable;

