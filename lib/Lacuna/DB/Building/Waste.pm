package Lacuna::DB::Result::Building::Waste;

use Moose;
extends 'Lacuna::DB::Result::Building';

__PACKAGE__->table('waste');

__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Result::Building::Waste::Recycling' => 'Lacuna::DB::Result::Building::Waste::Recycling',
    'Lacuna::DB::Result::Building::Waste::Sequestration' => 'Lacuna::DB::Result::Building::Waste::Sequestration',
    'Lacuna::DB::Result::Building::Waste::Treatment' => 'Lacuna::DB::Result::Building::Waste::Treatment',
});

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Waste));
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
