package Lacuna::DB::Building::Waste;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->table('waste');

__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Building::Waste::Recycling' => 'Lacuna::DB::Building::Waste::Recycling',
    'Lacuna::DB::Building::Waste::Sequestration' => 'Lacuna::DB::Building::Waste::Sequestration',
    'Lacuna::DB::Building::Waste::Treatment' => 'Lacuna::DB::Building::Waste::Treatment',
});

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Waste));
};

no Moose;
__PACKAGE__->meta->make_immutable;
