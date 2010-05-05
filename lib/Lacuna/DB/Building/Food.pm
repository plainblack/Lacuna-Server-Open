package Lacuna::DB::Building::Food;

use Moose;
extends 'Lacuna::DB::Building';

__PACKAGE__->table('food');

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Food));
};

__PACKAGE__->typecast_map(class => {
    'Lacuna::DB::Building::Food::Reserve' => 'Lacuna::DB::Building::Food::Reserve',
    'Lacuna::DB::Building::Food::Factory::Bread' => 'Lacuna::DB::Building::Food::Factory::Bread',
    'Lacuna::DB::Building::Food::Factory::Burger' => 'Lacuna::DB::Building::Food::Factory::Burger',
    'Lacuna::DB::Building::Food::Factory::Cheese' => 'Lacuna::DB::Building::Food::Factory::Cheese',
    'Lacuna::DB::Building::Food::Factory::Chip' => 'Lacuna::DB::Building::Food::Factory::Chip',
    'Lacuna::DB::Building::Food::Factory::Cider' => 'Lacuna::DB::Building::Food::Factory::Cider',
    'Lacuna::DB::Building::Food::Factory::CornMeal' => 'Lacuna::DB::Building::Food::Factory::CornMeal',
    'Lacuna::DB::Building::Food::Factory::Pancake' => 'Lacuna::DB::Building::Food::Factory::Pancake',
    'Lacuna::DB::Building::Food::Factory::Pie' => 'Lacuna::DB::Building::Food::Factory::Pie',
    'Lacuna::DB::Building::Food::Factory::Shake' => 'Lacuna::DB::Building::Food::Factory::Shake',
    'Lacuna::DB::Building::Food::Factory::Soup' => 'Lacuna::DB::Building::Food::Factory::Soup',
    'Lacuna::DB::Building::Food::Factory::Syrup' => 'Lacuna::DB::Building::Food::Factory::Syrup',
    'Lacuna::DB::Building::Food::Farm::Algae' => 'Lacuna::DB::Building::Food::Farm::Algae',
    'Lacuna::DB::Building::Food::Farm::Apple' => 'Lacuna::DB::Building::Food::Farm::Apple',
    'Lacuna::DB::Building::Food::Farm::Beeldeban' => 'Lacuna::DB::Building::Food::Farm::Beeldeban',
    'Lacuna::DB::Building::Food::Farm::Bean' => 'Lacuna::DB::Building::Food::Farm::Bean',
    'Lacuna::DB::Building::Food::Farm::Corn' => 'Lacuna::DB::Building::Food::Farm::Corn',
    'Lacuna::DB::Building::Food::Farm::Dairy' => 'Lacuna::DB::Building::Food::Farm::Dairy',
    'Lacuna::DB::Building::Food::Farm::Lapis' => 'Lacuna::DB::Building::Food::Farm::Lapis',
    'Lacuna::DB::Building::Food::Farm::Malcud' => 'Lacuna::DB::Building::Food::Farm::Malcud',
    'Lacuna::DB::Building::Food::Farm::Potato' => 'Lacuna::DB::Building::Food::Farm::Potato',
    'Lacuna::DB::Building::Food::Farm::Root' => 'Lacuna::DB::Building::Food::Farm::Root',
    'Lacuna::DB::Building::Food::Farm::Wheat' => 'Lacuna::DB::Building::Food::Farm::Wheat',
});


no Moose;
__PACKAGE__->meta->make_immutable;
