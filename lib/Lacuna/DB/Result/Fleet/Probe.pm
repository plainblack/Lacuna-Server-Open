package Lacuna::DB::Result::Fleet::Probe;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [{ class=> 'Lacuna::DB::Result::Building::Observatory',  level => 1 }];
use constant base_food_cost         => 100;
use constant base_water_cost        => 300;
use constant base_energy_cost       => 2000;
use constant base_ore_cost          => 1700;
use constant base_time_cost         => 3600;
use constant base_waste_cost        => 500;
use constant base_speed             => 5000;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant build_tags             => [qw(Exploration Intelligence)];

with "Lacuna::Role::Fleet::Send::Star";
with "Lacuna::Role::Fleet::Arrive::DeployProbe";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
