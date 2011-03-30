package Lacuna::Role::LCOT;

use Moose::Role;

use constant food_to_build => 21000;
use constant energy_to_build => 21000;
use constant ore_to_build => 21000;
use constant water_to_build => 21000;
use constant time_to_build => 60 * 2;
use constant food_consumption => 100;
use constant energy_consumption => 100;
use constant ore_consumption => 100;
use constant water_consumption => 100;
use constant waste_production => 100;
use constant max_instances_per_planet => 1;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Water Food Waste Energy Ore Storage Happiness));
};




1;
