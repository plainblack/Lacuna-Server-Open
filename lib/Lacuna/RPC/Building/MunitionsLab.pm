package Lacuna::RPC::Building::MunitionsLab;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/munitionslab';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::MunitionsLab';
}

no Moose;
__PACKAGE__->meta->make_immutable;

