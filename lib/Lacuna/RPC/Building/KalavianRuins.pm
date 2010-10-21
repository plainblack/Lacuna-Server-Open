package Lacuna::RPC::Building::KalavianRuins;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/kalavianruins';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::KalavianRuins';
}

no Moose;
__PACKAGE__->meta->make_immutable;

