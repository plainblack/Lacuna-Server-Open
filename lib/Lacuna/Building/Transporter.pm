package Lacuna::Building::Transporter;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/transporter';
}

sub model_class {
    return 'Lacuna::DB::Building::Transporter';
}

no Moose;
__PACKAGE__->meta->make_immutable;

