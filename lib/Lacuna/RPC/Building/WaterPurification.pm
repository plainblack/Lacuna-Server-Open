package Lacuna::RPC::Building::WaterPurification;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/waterpurification';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Water::Purification';
}

no Moose;
__PACKAGE__->meta->make_immutable;

