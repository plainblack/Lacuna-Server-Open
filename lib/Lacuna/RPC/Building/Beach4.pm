package Lacuna::RPC::Building::Beach4;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beach4';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Beach4';
}

no Moose;
__PACKAGE__->meta->make_immutable;

