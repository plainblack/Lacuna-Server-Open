package Lacuna::DB::Result::Fleet::Thud;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::MunitionsLab',  level => 3 } ];
use constant base_food_cost         => 7000;
use constant base_water_cost        => 8000;
use constant base_energy_cost       => 23000;
use constant base_ore_cost          => 45000;
use constant base_time_cost         => 60 * 60 * 2;
use constant base_waste_cost        => 8400;
use constant base_speed             => 700;
use constant base_stealth           => 1600;
use constant base_combat            => 2100;
use constant base_hold_size         => 0;
use constant build_tags             => ['War'];

with "Lacuna::Role::Fleet::Send::Planet";
with "Lacuna::Role::Fleet::Send::Inhabited";
with "Lacuna::Role::Fleet::Send::NotIsolationist";
with "Lacuna::Role::Fleet::Send::IsHostile";
with "Lacuna::Role::Fleet::Arrive::TriggerDefense";
with "Lacuna::Role::Fleet::Arrive::DeploySmolderingCrater";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
