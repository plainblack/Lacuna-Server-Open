package Lacuna::RPC::Building::GeoThermalVent;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/geothermalvent';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::GeoThermalVent';
}

no Moose;
__PACKAGE__->meta->make_immutable;

