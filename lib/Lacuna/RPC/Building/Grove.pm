package Lacuna::RPC::Building::Grove;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/grove';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Grove';
}

no Moose;
__PACKAGE__->meta->make_immutable;

