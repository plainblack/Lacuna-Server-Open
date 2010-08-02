package Lacuna::RPC::Building::WaterReclamation;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/waterreclamation';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Water::Reclamation';
}

no Moose;
__PACKAGE__->meta->make_immutable;

