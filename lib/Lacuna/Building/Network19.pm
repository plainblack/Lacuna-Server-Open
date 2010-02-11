package Lacuna::Building::Network19;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/network19';
}

sub model_class {
    return 'Lacuna::DB::Building::Network19';
}

no Moose;
__PACKAGE__->meta->make_immutable;

