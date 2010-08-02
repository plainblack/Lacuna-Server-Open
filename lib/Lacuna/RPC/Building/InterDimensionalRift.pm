package Lacuna::RPC::Building::InterDimensionalRift;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/interdimensionalrift';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::InterDimensionalRift';
}

no Moose;
__PACKAGE__->meta->make_immutable;

