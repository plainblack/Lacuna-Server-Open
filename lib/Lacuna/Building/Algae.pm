package Lacuna::Building::Algae;

use Moose;
extends 'Lacuna::Building';

sub model_class {
    return 'Lacuna::DB::Result::Building::Food::Algae';
}

sub app_url {
    return '/algae';
}

no Moose;
__PACKAGE__->meta->make_immutable;

