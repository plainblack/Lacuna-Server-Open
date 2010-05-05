package Lacuna::Building::Cheese;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/cheese';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Factory::Cheese';
}

no Moose;
__PACKAGE__->meta->make_immutable;

