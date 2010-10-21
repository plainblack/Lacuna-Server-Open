package Lacuna::RPC::Building::Propulsion;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/propulsion';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Propulsion';
}

no Moose;
__PACKAGE__->meta->make_immutable;

