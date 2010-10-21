package Lacuna::RPC::Building::CornMeal;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/cornmeal';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::CornMeal';
}

no Moose;
__PACKAGE__->meta->make_immutable;

