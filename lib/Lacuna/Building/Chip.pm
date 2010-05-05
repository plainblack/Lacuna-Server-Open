package Lacuna::Building::Chip;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/chip';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Factory::Chip';
}

no Moose;
__PACKAGE__->meta->make_immutable;

