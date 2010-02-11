package Lacuna::Building::Embassy;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/embassy';
}

sub model_class {
    return 'Lacuna::DB::Building::Embassy';
}

no Moose;
__PACKAGE__->meta->make_immutable;

