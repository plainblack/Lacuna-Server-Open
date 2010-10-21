package Lacuna::RPC::Building::Algae;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Algae';
}

sub app_url {
    return '/algae';
}

no Moose;
__PACKAGE__->meta->make_immutable;

