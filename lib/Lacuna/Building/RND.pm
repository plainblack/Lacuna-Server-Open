package Lacuna::Building::RND;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Building::RND';
}

no Moose;
__PACKAGE__->meta->make_immutable;

