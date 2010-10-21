package Lacuna::RPC::Building::Mine;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/mine';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Ore::Mine';
}

no Moose;
__PACKAGE__->meta->make_immutable;

