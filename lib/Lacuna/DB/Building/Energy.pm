package Lacuna::DB::Building::Energy;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('energy');

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Energy));
};

no Moose;
__PACKAGE__->meta->make_immutable;
