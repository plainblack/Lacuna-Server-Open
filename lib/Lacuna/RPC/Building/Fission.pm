package Lacuna::RPC::Building::Fission;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/fission';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Energy::Fission';
}

no Moose;
__PACKAGE__->meta->make_immutable;

