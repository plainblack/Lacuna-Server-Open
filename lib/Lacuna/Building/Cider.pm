package Lacuna::Building::Cider;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/cider';
}

sub model_class {
    return 'Lacuna::DB::Building::Food::Factory::Cider';
}

no Moose;
__PACKAGE__->meta->make_immutable;

