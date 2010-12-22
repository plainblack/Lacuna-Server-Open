package Lacuna::RPC::Building::GreatBallOfJunk;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/greatballofjunk';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::GreatBallOfJunk';
}

no Moose;
__PACKAGE__->meta->make_immutable;

