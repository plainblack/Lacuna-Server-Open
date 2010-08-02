package Lacuna::RPC::Building::Crater;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/crater';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Crater';
}

no Moose;
__PACKAGE__->meta->make_immutable;

