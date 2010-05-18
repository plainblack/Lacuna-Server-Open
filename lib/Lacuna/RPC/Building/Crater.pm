package Lacuna::RPC::Building::Crater;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/crater';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Crater';
}

no Moose;
__PACKAGE__->meta->make_immutable;

