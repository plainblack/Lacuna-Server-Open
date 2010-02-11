package Lacuna::Building::Observatory;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/observatory';
}

sub model_class {
    return 'Lacuna::DB::Building::Observatory';
}

no Moose;
__PACKAGE__->meta->make_immutable;

