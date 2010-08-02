package Lacuna::RPC::Building::Soup;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/soup';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Soup';
}

no Moose;
__PACKAGE__->meta->make_immutable;

