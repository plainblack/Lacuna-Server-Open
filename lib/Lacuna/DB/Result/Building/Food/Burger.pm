package Lacuna::DB::Result::Building::Food::Burger;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

use constant controller_class => 'Lacuna::RPC::Building::Burger';

use constant image => 'burger';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Malcud'=>5};

use constant name => 'Malcud Burger Packer';

use constant food_to_build => 135;

use constant energy_to_build => 135;

use constant ore_to_build => 135;

use constant water_to_build => 135;

use constant waste_to_build => 100;

use constant time_to_build => 100;

use constant food_consumption => 10;

use constant burger_production => 30;

use constant energy_consumption => 8;

use constant ore_consumption => 4;

use constant water_consumption => 2;

use constant waste_production => 14;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(burger);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
