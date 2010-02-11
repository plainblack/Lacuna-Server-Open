package Lacuna::Building::Soup;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/soup';
}

sub model_class {
    return 'Lacuna::DB::Building::Food::Factory::Soup';
}

no Moose;
__PACKAGE__->meta->make_immutable;

