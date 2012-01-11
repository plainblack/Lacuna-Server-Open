package Lacuna::DB::Result::Ships::Excavator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => { class=> 'Lacuna::DB::Result::Building::Archaeology',  level => 15 };
# use constant base_food_cost         => 400;
# use constant base_water_cost        => 1000;
# use constant base_energy_cost       => 8500;
# use constant base_ore_cost          => 11000;
# use constant base_time_cost         => 20000;
# use constant base_waste_cost        => 1200;
# use constant base_speed             => 1800;
use constant base_food_cost         => 100000;
use constant base_water_cost        => 200000;
use constant base_energy_cost       => 500000;
use constant base_ore_cost          => 900000;
use constant base_time_cost         => 8 * 60 * 60;
use constant base_waste_cost        => 300000;
use constant base_speed             => 1000;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant build_tags             => ['Exploration'];

with "Lacuna::Role::Ship::Send::Asteroid";
with "Lacuna::Role::Ship::Arrive::DeployExcavator";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
