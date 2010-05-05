package Lacuna::Building::University;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/university';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::University';
}

no Moose;
__PACKAGE__->meta->make_immutable;

