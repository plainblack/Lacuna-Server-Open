package Lacuna::RPC::Building::MetalJunkArches;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/metaljunkarches';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::MetalJunkArches';
}

no Moose;
__PACKAGE__->meta->make_immutable;

