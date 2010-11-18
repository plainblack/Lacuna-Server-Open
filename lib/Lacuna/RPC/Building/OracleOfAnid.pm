package Lacuna::RPC::Building::AlgaePond;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/algaepond';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::AlgaePond';
}

no Moose;
__PACKAGE__->meta->make_immutable;

