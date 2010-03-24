package Lacuna::DB::Building::Waste;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->set_domain_name('waste');

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Waste));
};

no Moose;
__PACKAGE__->meta->make_immutable;
