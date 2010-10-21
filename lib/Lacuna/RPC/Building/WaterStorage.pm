package Lacuna::RPC::Building::WaterStorage;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/waterstorage';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Water::Storage';
}

no Moose;
__PACKAGE__->meta->make_immutable;

