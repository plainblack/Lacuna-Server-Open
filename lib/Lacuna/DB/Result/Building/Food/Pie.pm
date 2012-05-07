package Lacuna::DB::Result::Building::Food::Pie;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';

use constant controller_class => 'Lacuna::RPC::Building::Pie';

use constant image => 'pie';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Lapis'=>5};

use constant name => 'Lapis Pie Bakery';

use constant food_to_build => 135;

use constant energy_to_build => 135;

use constant ore_to_build => 135;

use constant water_to_build => 135;

use constant waste_to_build => 100;

use constant time_to_build => 100;

use constant food_consumption => 10;

use constant pie_production => 30;

use constant energy_consumption => 5;

use constant ore_consumption => 5;

use constant water_consumption => 4;

use constant waste_production => 14;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(pie);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
