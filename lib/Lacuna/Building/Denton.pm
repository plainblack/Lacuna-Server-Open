package Lacuna::Building::Denton;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/denton';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Farm::Root';
}

no Moose;
__PACKAGE__->meta->make_immutable;

