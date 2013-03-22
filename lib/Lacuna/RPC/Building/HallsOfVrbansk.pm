package Lacuna::RPC::Building::HallsOfVrbansk;

use Moose;
use utf8;
use List::Util qw(min);

no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/hallsofvrbansk';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk';
}

__PACKAGE__->register_rpc_method_names();

no Moose;
__PACKAGE__->meta->make_immutable;

