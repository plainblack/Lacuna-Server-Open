package Lacuna::Building::WaterReclamation;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/waterreclamation';
}

sub model_class {
    return 'Lacuna::DB::Building::Water::Reclamation';
}

no Moose;
__PACKAGE__->meta->make_immutable;

