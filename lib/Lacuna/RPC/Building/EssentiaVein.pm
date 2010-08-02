package Lacuna::RPC::Building::EssentiaVein;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/essentiavein';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::EssentiaVein';
}

no Moose;
__PACKAGE__->meta->make_immutable;

