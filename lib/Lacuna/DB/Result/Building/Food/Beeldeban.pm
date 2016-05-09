package Lacuna::DB::Result::Building::Food::Beeldeban;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Food';
use Lacuna::Constants qw(GROWTH_F INFLATION_N CONSUME_S);

use constant controller_class => 'Lacuna::RPC::Building::Beeldeban';

use constant building_prereq => {'Lacuna::DB::Result::Building::Food::Root'=>5};

use constant prod_rate => GROWTH_F;

use constant consume_rate => CONSUME_S;

use constant cost_rate => INFLATION_N;

use constant image => 'beeldeban';

use constant min_orbit => 5;

use constant max_orbit => 6;

use constant name => 'Beeldeban Herder';

use constant food_to_build => 100;

use constant energy_to_build => 100;

use constant ore_to_build => 125;

use constant water_to_build => 76;

use constant waste_to_build => 35;

use constant time_to_build => 100;

use constant food_consumption => 19;

use constant beetle_production => 50;

use constant energy_consumption => 1;

use constant ore_consumption => 2;

use constant water_consumption => 3;

use constant waste_production => 11;

use constant waste_consumption => 3;

around produces_food_items => sub {
    my ($orig, $class) = @_;
    my $foods = $orig->($class);
    push @{$foods}, qw(beetle);
    return $foods;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
