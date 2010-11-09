package Lacuna::RPC::Building::PantheonOfHagness;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/pantheonofhagness';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::PantheonOfHagness';
}

no Moose;
__PACKAGE__->meta->make_immutable;

