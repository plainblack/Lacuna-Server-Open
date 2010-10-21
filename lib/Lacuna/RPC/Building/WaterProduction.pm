package Lacuna::RPC::Building::WaterProduction;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/waterproduction';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Water::Production';
}

no Moose;
__PACKAGE__->meta->make_immutable;

