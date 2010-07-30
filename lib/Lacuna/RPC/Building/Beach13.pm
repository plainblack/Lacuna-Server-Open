package Lacuna::RPC::Building::Beach13;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beach13';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Beach13';
}

no Moose;
__PACKAGE__->meta->make_immutable;

