package Lacuna::RPC::Building::Chip;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/chip';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Chip';
}

no Moose;
__PACKAGE__->meta->make_immutable;

