package Lacuna::RPC::Building::Ravine;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/ravine';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Ravine';
}

no Moose;
__PACKAGE__->meta->make_immutable;

