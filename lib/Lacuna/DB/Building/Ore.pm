package Lacuna::DB::Building::Ore;

use Moose;
extends 'Lacuna::DB::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Ore));
};

__PACKAGE__->set_domain_name('ore');


no Moose;
__PACKAGE__->meta->make_immutable;
