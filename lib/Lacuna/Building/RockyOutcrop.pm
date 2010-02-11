package Lacuna::Building::RockyOutcrop;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/rockyoutcrop';
}

sub model_class {
    return 'Lacuna::DB::Building::Permanent::RockyOutcrop';
}

no Moose;
__PACKAGE__->meta->make_immutable;

