package Lacuna::DB::Result::Ships::Detonator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::MunitionsLab',  level => 1 } ];
use constant base_food_cost         => 6000;
use constant base_water_cost        => 15600;
use constant base_energy_cost       => 113600;
use constant base_ore_cost          => 97200;
use constant base_time_cost         => 86400;
use constant base_waste_cost        => 25200;
use constant base_combat            => 1850;
use constant base_speed             => 1000;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant build_tags             => ['War'];

with "Lacuna::Role::Ship::Send::NeutralArea";
with "Lacuna::Role::Ship::Send::AsteroidStarUninhabited";
with "Lacuna::Role::Ship::Send::IsHostile";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::DestroyProbes";
with "Lacuna::Role::Ship::Arrive::DestroyMinersExcavators";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
