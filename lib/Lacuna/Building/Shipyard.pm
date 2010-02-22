package Lacuna::Building::Shipyard;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/shipyard';
}

sub model_class {
    return 'Lacuna::DB::Building::Shipyard';
}

no Moose;
__PACKAGE__->meta->make_immutable;

