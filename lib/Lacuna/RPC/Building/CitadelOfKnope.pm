package Lacuna::RPC::Building::CitadelOfKnope;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/citadelofknope';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::CitadelOfKnope';
}

no Moose;
__PACKAGE__->meta->make_immutable;

