package Lacuna::RPC::Building::LuxuryHousing;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/luxuryhousing';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::LuxuryHousing';
}

no Moose;
__PACKAGE__->meta->make_immutable;

