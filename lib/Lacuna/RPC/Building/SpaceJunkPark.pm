package Lacuna::RPC::Building::SpaceJunkPark;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/spacejunkpark';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::SpaceJunkPark';
}

no Moose;
__PACKAGE__->meta->make_immutable;

