package Lacuna::Building::Park;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/park';
}

sub model_class {
    return 'Lacuna::DB::Building::Park';
}

no Moose;
__PACKAGE__->meta->make_immutable;

