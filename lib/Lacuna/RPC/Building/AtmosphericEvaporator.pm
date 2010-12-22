package Lacuna::RPC::Building::AtmosphericEvaporator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/atmosphericevaporator';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Water::AtmosphericEvaporator';
}

no Moose;
__PACKAGE__->meta->make_immutable;

