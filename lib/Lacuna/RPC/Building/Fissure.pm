package Lacuna::RPC::Building::Fissure;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/fissure';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Fissure';
}

no Moose;
__PACKAGE__->meta->make_immutable;

