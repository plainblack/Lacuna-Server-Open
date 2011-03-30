package Lacuna::RPC::Building::LCOTa;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/lcota';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::LCOTa';
}



__PACKAGE__->register_rpc_method_names(qw());


no Moose;
__PACKAGE__->meta->make_immutable;

