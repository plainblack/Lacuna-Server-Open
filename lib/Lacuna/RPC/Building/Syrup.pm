package Lacuna::RPC::Building::Syrup;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/syrup';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Syrup';
}

no Moose;
__PACKAGE__->meta->make_immutable;

