package Lacuna::RPC::Building::RockyOutcrop;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/rockyoutcrop';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::RockyOutcrop';
}

no Moose;
__PACKAGE__->meta->make_immutable;

