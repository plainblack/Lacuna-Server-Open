package Lacuna::Building::Apple;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/apple';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Farm::Apple';
}

no Moose;
__PACKAGE__->meta->make_immutable;

