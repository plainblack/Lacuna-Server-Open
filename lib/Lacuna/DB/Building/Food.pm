package Lacuna::DB::Building::Food;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('food');

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Food));
};

no Moose;
__PACKAGE__->meta->make_immutable;
