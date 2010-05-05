package Lacuna::Building::Corn;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/corn';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Farm::Corn';
}

no Moose;
__PACKAGE__->meta->make_immutable;

