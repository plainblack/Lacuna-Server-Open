package Lacuna::DB::Result::Building::Ore;

use Moose;
extends 'Lacuna::DB::Result::Building';

__PACKAGE__->table('ore');

#__PACKAGE__->typecast_map(class => {
#    'Lacuna::DB::Result::Building::Ore::Mine' => 'Lacuna::DB::Result::Building::Ore::Mine',
#    'Lacuna::DB::Result::Building::Ore::Ministry' => 'Lacuna::DB::Result::Building::Ore::Ministry',
#    'Lacuna::DB::Result::Building::Ore::Platform' => 'Lacuna::DB::Result::Building::Ore::Platform',
#    'Lacuna::DB::Result::Building::Ore::Refinery' => 'Lacuna::DB::Result::Building::Ore::Refinery',
#    'Lacuna::DB::Result::Building::Ore::Storage' => 'Lacuna::DB::Result::Building::Ore::Storage',
#});


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Ore));
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
