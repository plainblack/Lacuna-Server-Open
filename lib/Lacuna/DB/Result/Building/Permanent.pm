package Lacuna::DB::Result::Building::Permanent;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

sub sortable_name {
    '25'.shift->name
}

# permanent buildings come with no population
sub _build_population {
    0
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
