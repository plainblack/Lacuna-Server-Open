package Lacuna::RPC::Building::CloakingLab;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/cloakinglab';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::CloakingLab';
}

no Moose;
__PACKAGE__->meta->make_immutable;

