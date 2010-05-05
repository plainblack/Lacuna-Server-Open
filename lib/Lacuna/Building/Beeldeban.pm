package Lacuna::Building::Beeldeban;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/beeldeban';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Farm::Beeldeban';
}

no Moose;
__PACKAGE__->meta->make_immutable;

