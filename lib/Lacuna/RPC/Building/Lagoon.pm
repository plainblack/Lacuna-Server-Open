package Lacuna::RPC::Building::Lagoon;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/lagoon';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::Lagoon';
}

no Moose;
__PACKAGE__->meta->make_immutable;

