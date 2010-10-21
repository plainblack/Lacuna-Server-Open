package Lacuna::RPC::Building::WasteDigester;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/wastedigester';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Waste::Digester';
}

no Moose;
__PACKAGE__->meta->make_immutable;

