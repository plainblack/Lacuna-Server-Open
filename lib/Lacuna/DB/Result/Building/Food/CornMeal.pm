package Lacuna::DB::Result::Building::Food::CornMeal;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

use constant controller_class => 'Lacuna::RPC::Building::CornMeal';

use constant image => 'meal';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Corn'=>5};

use constant name => 'Corn Meal Grinder';

use constant food_to_build => 140;

use constant energy_to_build => 140;

use constant ore_to_build => 140;

use constant water_to_build => 150;

use constant waste_to_build => 100;

use constant time_to_build => 100;

use constant food_consumption => 10;

use constant meal_production => 30;

use constant energy_consumption => 5;

use constant ore_consumption => 5;

use constant water_consumption => 5;

use constant waste_production => 15;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(meal);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
