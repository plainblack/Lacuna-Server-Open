package Lacuna::RPC::Building::WasteSequestration;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/wastesequestration';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Waste::Sequestration';
}

no Moose;
__PACKAGE__->meta->make_immutable;

