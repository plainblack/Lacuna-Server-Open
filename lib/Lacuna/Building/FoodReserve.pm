package Lacuna::Building::FoodReserve;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/foodreserve';
}

sub model_class {
    return 'Lacuna::DB::Building::Food::Reserve';
}

no Moose;
__PACKAGE__->meta->make_immutable;

