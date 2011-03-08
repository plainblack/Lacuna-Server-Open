package Lacuna::RPC::Building::SSLb;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/sslb';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::SSLb';
}


__PACKAGE__->register_rpc_method_names(qw());


no Moose;
__PACKAGE__->meta->make_immutable;

