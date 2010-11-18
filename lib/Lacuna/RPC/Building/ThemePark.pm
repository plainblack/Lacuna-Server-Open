package Lacuna::RPC::Building::ThemePark;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/themepark';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::ThemePark';
}

no Moose;
__PACKAGE__->meta->make_immutable;

