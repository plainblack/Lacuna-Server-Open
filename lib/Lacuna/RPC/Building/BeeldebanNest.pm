package Lacuna::RPC::Building::BeeldebanNest;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/beeldebannest';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::BeeldebanNest';
}

no Moose;
__PACKAGE__->meta->make_immutable;

