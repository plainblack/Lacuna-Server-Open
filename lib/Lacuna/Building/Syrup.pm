package Lacuna::Building::Syrup;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/syrup';
}

sub model_class {
    return 'Lacuna::DB::Building::Food::Factory::Syrup';
}

no Moose;
__PACKAGE__->meta->make_immutable;

