package Lacuna::RPC::Building::LCOTi;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/lcoti';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::LCOTi';
}



__PACKAGE__->register_rpc_method_names(qw());


no Moose;
__PACKAGE__->meta->make_immutable;

