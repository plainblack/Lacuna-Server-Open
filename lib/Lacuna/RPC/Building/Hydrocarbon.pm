package Lacuna::RPC::Building::Hydrocarbon;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/hydrocarbon';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Energy::Hydrocarbon';
}

no Moose;
__PACKAGE__->meta->make_immutable;

