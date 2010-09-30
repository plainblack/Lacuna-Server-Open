package Lacuna::RPC::Building::Sand;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/sand';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Sand';
}

no Moose;
__PACKAGE__->meta->make_immutable;

