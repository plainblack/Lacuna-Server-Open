package Lacuna::RPC::Building::SAW;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/saw';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::SAW';
}

no Moose;
__PACKAGE__->meta->make_immutable;

