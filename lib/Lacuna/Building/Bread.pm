package Lacuna::Building::Bread;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/bread';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Bread';
}

no Moose;
__PACKAGE__->meta->make_immutable;

