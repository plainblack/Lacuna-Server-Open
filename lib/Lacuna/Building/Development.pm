package Lacuna::Building::Development;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/development';
}

sub model_class {
    return 'Lacuna::DB::Building::Development';
}

no Moose;
__PACKAGE__->meta->make_immutable;

