package Lacuna::RPC::Building::TheDillonForge;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/thedillonforge';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::TheDillonForge';
}

no Moose;
__PACKAGE__->meta->make_immutable;

