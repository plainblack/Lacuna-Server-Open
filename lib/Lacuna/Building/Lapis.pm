package Lacuna::Building::Lapis;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/lapis';
}

sub model_class {
    return 'Lacuna::DB::Building::Food::Farm::Lapis';
}

no Moose;
__PACKAGE__->meta->make_immutable;

