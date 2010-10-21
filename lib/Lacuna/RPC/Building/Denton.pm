package Lacuna::RPC::Building::Denton;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/denton';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Root';
}

no Moose;
__PACKAGE__->meta->make_immutable;

