package Lacuna::DB::Result::Building::Food::Cheese;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

use constant controller_class => 'Lacuna::RPC::Building::Cheese';

use constant image => 'cheese';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Dairy'=>5};

use constant name => 'Cheese Maker';

use constant food_to_build => 175;

use constant energy_to_build => 175;

use constant ore_to_build => 175;

use constant water_to_build => 175;

use constant waste_to_build => 90;

use constant time_to_build => 100;

use constant food_consumption => 10;

use constant cheese_production => 30;

use constant energy_consumption => 15;

use constant ore_consumption => 1;

use constant water_consumption => 15;

use constant waste_production => 31;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(cheese);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
