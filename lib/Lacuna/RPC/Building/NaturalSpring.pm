package Lacuna::RPC::Building::NaturalSpring;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/naturalspring';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::NaturalSpring';
}

no Moose;
__PACKAGE__->meta->make_immutable;

