package Lacuna::DB::Result::Building::Food;

use Moose;
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Food));
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
