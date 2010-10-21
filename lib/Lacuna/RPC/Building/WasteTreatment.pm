package Lacuna::RPC::Building::WasteTreatment;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/wastetreatment';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Waste::Treatment';
}

no Moose;
__PACKAGE__->meta->make_immutable;

