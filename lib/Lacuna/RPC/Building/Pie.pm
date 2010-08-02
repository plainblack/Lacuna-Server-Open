package Lacuna::RPC::Building::Pie;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/pie';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Pie';
}

no Moose;
__PACKAGE__->meta->make_immutable;

