package Lacuna::Building::SpacePort;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/spaceport';
}

sub model_class {
    return 'Lacuna::DB::Building::SpacePort';
}

no Moose;
__PACKAGE__->meta->make_immutable;

