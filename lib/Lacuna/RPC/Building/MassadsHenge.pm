package Lacuna::RPC::Building::MassadsHenge;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/massadshenge';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::MassadsHenge';
}

no Moose;
__PACKAGE__->meta->make_immutable;

