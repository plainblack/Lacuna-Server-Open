package Lacuna::RPC::Building::Volcano;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/volcano';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Volcano';
}

no Moose;
__PACKAGE__->meta->make_immutable;

