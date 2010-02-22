package Lacuna::Building::WasteSequestration;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/wastesequestration';
}

sub model_class {
    return 'Lacuna::DB::Building::Waste::Sequestration';
}

no Moose;
__PACKAGE__->meta->make_immutable;

