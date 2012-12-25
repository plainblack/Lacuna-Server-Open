package Lacuna::DB::Result::Fleet::Sweeper;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::MunitionsLab',  level => 16 } ];
use constant base_food_cost         => 5000;
use constant base_water_cost        => 12000;
use constant base_energy_cost       => 70000;
use constant base_ore_cost          => 75000;
use constant base_time_cost         => 60 * 60 * 7;
use constant base_waste_cost        => 20000;
use constant base_combat            => 8100;
use constant base_speed             => 2600;
use constant base_stealth           => 2800;
use constant pilotable              => 1;
use constant build_tags             => ['War'];

with "Lacuna::Role::Fleet::Send::Body";
with "Lacuna::Role::Fleet::Send::NotIsolationist";
with "Lacuna::Role::Fleet::Send::IsHostile";
with "Lacuna::Role::Fleet::Send::RecallWhileTravelling";
with "Lacuna::Role::Fleet::Arrive::TriggerDefense";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
