package Lacuna::RPC::Building::Beach1;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beach1';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Beach1';
}

no Moose;
__PACKAGE__->meta->make_immutable;

