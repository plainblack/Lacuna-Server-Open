package Lacuna::DB::Building::Ore;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->table('ore');

__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Building::Ore::Mine' => 'Lacuna::DB::Building::Ore::Mine',
    'Lacuna::DB::Building::Ore::Ministry' => 'Lacuna::DB::Building::Ore::Ministry',
    'Lacuna::DB::Building::Ore::Platform' => 'Lacuna::DB::Building::Ore::Platform',
    'Lacuna::DB::Building::Ore::Refinery' => 'Lacuna::DB::Building::Ore::Refinery',
    'Lacuna::DB::Building::Ore::Storage' => 'Lacuna::DB::Building::Ore::Storage',
});


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Ore));
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
