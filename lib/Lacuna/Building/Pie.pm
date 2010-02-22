package Lacuna::Building::Pie;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/pie';
}

sub model_class {
    return 'Lacuna::DB::Building::Food::Factory::Pie';
}

no Moose;
__PACKAGE__->meta->make_immutable;

