package Lacuna::RPC::Building::Lake;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/lake';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Lake';
}

no Moose;
__PACKAGE__->meta->make_immutable;

