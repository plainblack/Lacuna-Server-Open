package Lacuna::DB::Result::Building::Food;

use Moose;
extends 'Lacuna::DB::Result::Building';

__PACKAGE__->table('food');

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Food));
};

#__PACKAGE__->typecast_map(class => {
#    'Lacuna::DB::Result::Building::Food::Reserve' => 'Lacuna::DB::Result::Building::Food::Reserve',
#    'Lacuna::DB::Result::Building::Food::Factory::Bread' => 'Lacuna::DB::Result::Building::Food::Factory::Bread',
#    'Lacuna::DB::Result::Building::Food::Factory::Burger' => 'Lacuna::DB::Result::Building::Food::Factory::Burger',
#    'Lacuna::DB::Result::Building::Food::Factory::Cheese' => 'Lacuna::DB::Result::Building::Food::Factory::Cheese',
#    'Lacuna::DB::Result::Building::Food::Factory::Chip' => 'Lacuna::DB::Result::Building::Food::Factory::Chip',
#    'Lacuna::DB::Result::Building::Food::Factory::Cider' => 'Lacuna::DB::Result::Building::Food::Factory::Cider',
#    'Lacuna::DB::Result::Building::Food::Factory::CornMeal' => 'Lacuna::DB::Result::Building::Food::Factory::CornMeal',
#    'Lacuna::DB::Result::Building::Food::Factory::Pancake' => 'Lacuna::DB::Result::Building::Food::Factory::Pancake',
#    'Lacuna::DB::Result::Building::Food::Factory::Pie' => 'Lacuna::DB::Result::Building::Food::Factory::Pie',
#    'Lacuna::DB::Result::Building::Food::Factory::Shake' => 'Lacuna::DB::Result::Building::Food::Factory::Shake',
#    'Lacuna::DB::Result::Building::Food::Factory::Soup' => 'Lacuna::DB::Result::Building::Food::Factory::Soup',
#    'Lacuna::DB::Result::Building::Food::Factory::Syrup' => 'Lacuna::DB::Result::Building::Food::Factory::Syrup',
#    'Lacuna::DB::Result::Building::Food::Farm::Algae' => 'Lacuna::DB::Result::Building::Food::Farm::Algae',
#    'Lacuna::DB::Result::Building::Food::Farm::Apple' => 'Lacuna::DB::Result::Building::Food::Farm::Apple',
#    'Lacuna::DB::Result::Building::Food::Farm::Beeldeban' => 'Lacuna::DB::Result::Building::Food::Farm::Beeldeban',
#    'Lacuna::DB::Result::Building::Food::Farm::Bean' => 'Lacuna::DB::Result::Building::Food::Farm::Bean',
#    'Lacuna::DB::Result::Building::Food::Farm::Corn' => 'Lacuna::DB::Result::Building::Food::Farm::Corn',
#    'Lacuna::DB::Result::Building::Food::Farm::Dairy' => 'Lacuna::DB::Result::Building::Food::Farm::Dairy',
#    'Lacuna::DB::Result::Building::Food::Farm::Lapis' => 'Lacuna::DB::Result::Building::Food::Farm::Lapis',
#    'Lacuna::DB::Result::Building::Food::Farm::Malcud' => 'Lacuna::DB::Result::Building::Food::Farm::Malcud',
#    'Lacuna::DB::Result::Building::Food::Farm::Potato' => 'Lacuna::DB::Result::Building::Food::Farm::Potato',
#    'Lacuna::DB::Result::Building::Food::Farm::Root' => 'Lacuna::DB::Result::Building::Food::Farm::Root',
#    'Lacuna::DB::Result::Building::Food::Farm::Wheat' => 'Lacuna::DB::Result::Building::Food::Farm::Wheat',
#});


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
