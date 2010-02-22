package Lacuna::Building::PlanetaryCommand;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/planetarycommand';
}

sub model_class {
    return 'Lacuna::DB::Building::PlanetaryCommand';
}

no Moose;
__PACKAGE__->meta->make_immutable;

