package Lacuna::Building::Wheat;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/wheat';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Farm::Wheat';
}

no Moose;
__PACKAGE__->meta->make_immutable;

