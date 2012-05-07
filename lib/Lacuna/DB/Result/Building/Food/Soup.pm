package Lacuna::DB::Result::Building::Food::Soup;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

use constant controller_class => 'Lacuna::RPC::Building::Soup';

use constant image => 'cannery';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Bean'=>5};

use constant name => 'Amalgus Bean Soup Cannery';

use constant food_to_build => 125;

use constant energy_to_build => 125;

use constant ore_to_build => 168;

use constant water_to_build => 125;

use constant waste_to_build => 100;

use constant time_to_build => 100;

use constant food_consumption => 10;

use constant soup_production => 30;

use constant energy_consumption => 4;

use constant ore_consumption => 1;

use constant water_consumption => 14;

use constant waste_production => 18;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(soup);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
