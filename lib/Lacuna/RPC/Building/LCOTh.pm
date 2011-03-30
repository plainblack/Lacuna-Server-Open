package Lacuna::RPC::Building::LCOTh;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/lcoth';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::LCOTh';
}



__PACKAGE__->register_rpc_method_names(qw());


no Moose;
__PACKAGE__->meta->make_immutable;

