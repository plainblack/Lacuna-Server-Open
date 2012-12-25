package Lacuna::DB::Result::Fleet::Excavator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Archaeology',  level => 11 } ];
use constant base_food_cost         => 3000;
use constant base_water_cost        => 5000;
use constant base_energy_cost       => 20000;
use constant base_ore_cost          => 80000;
use constant base_time_cost         => 8 * 60 * 60;
use constant base_waste_cost        => 10000;
use constant base_speed             => 1000;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant build_tags             => ['Exploration'];

with "Lacuna::Role::Fleet::Send::AsteroidAndUninhabited";
with "Lacuna::Role::Fleet::Arrive::TriggerDefense";
with "Lacuna::Role::Fleet::Arrive::DeployExcavator";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
