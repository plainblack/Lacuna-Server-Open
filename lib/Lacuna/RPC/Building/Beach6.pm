package Lacuna::RPC::Building::Beach6;

use Moose;
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beach6';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Beach6';
}

no Moose;
__PACKAGE__->meta->make_immutable;

