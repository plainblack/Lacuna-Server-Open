package Lacuna::RPC::Building::GasGiantPlatform;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/gasgiantplatform';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::GasGiantPlatform';
}

no Moose;
__PACKAGE__->meta->make_immutable;

