package Lacuna::Building::Potato;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/potato';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Farm::Potato';
}

no Moose;
__PACKAGE__->meta->make_immutable;

