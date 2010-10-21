package Lacuna::RPC::Building::GeneticsLab;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/geneticslab';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::GeneticsLab';
}

no Moose;
__PACKAGE__->meta->make_immutable;

