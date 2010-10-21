package Lacuna::RPC::Building::Capitol;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/capitol';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Capitol';
}



no Moose;
__PACKAGE__->meta->make_immutable;

