package Lacuna::RPC::Building::DentonBrambles;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/dentonbrambles';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::DentonBrambles';
}

no Moose;
__PACKAGE__->meta->make_immutable;
