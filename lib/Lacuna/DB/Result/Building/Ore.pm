package Lacuna::DB::Result::Building::Ore;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Ore));
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
