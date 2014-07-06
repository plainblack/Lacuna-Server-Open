package Lacuna::RPC::Building::Parliament;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Guard qw(guard);

sub app_url {
    return '/parliament';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Module::Parliament';
}

__PACKAGE__->register_rpc_method_names();

no Moose;
__PACKAGE__->meta->make_immutable;

