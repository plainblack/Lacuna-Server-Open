package Lacuna::Building::Trade;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/trade';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Trade';
}

no Moose;
__PACKAGE__->meta->make_immutable;

