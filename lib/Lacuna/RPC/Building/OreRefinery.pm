package Lacuna::RPC::Building::OreRefinery;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/orerefinery';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Ore::Refinery';
}

no Moose;
__PACKAGE__->meta->make_immutable;

