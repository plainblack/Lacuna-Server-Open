package Lacuna::Building::Burger;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/burger';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Burger';
}

no Moose;
__PACKAGE__->meta->make_immutable;

