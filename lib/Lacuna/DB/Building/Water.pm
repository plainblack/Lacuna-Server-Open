package Lacuna::DB::Building::Water;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('water');

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Water));
};

no Moose;
__PACKAGE__->meta->make_immutable;
