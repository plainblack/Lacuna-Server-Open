package Lacuna::RPC::Building::Beeldeban;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beeldeban';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Beeldeban';
}

no Moose;
__PACKAGE__->meta->make_immutable;

