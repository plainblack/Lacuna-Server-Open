package Lacuna::DB::Result::Ships::Bleeder;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::MunitionsLab',  level => 12 } ];
use constant base_food_cost         => 8000;
use constant base_water_cost        => 21000;
use constant base_energy_cost       => 69010;
use constant base_ore_cost          => 95020;
use constant base_time_cost         => 60 * 60 * 13;
use constant base_waste_cost        => 12200;
use constant base_speed             => 600;
use constant base_stealth           => 2850;
use constant base_combat            => 1700;
use constant base_hold_size         => 0;
use constant build_tags             => ['War'];

with "Lacuna::Role::Ship::Send::NeutralArea";
with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::Inhabited";
with "Lacuna::Role::Ship::Send::NotIsolationist";
with "Lacuna::Role::Ship::Send::IsHostile";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::DeployBleeder";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
