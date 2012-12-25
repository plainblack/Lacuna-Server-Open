package Lacuna::DB::Result::Fleet::ObservatorySeeker;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::MunitionsLab',  level => 10 }];
use constant base_food_cost         => 20000;
use constant base_water_cost        => 50000;
use constant base_energy_cost       => 170000;
use constant base_ore_cost          => 200000;
use constant base_time_cost         => 58500;
use constant base_waste_cost        => 40000;
use constant base_speed             => 1000;
use constant base_combat            => 2500;
use constant base_stealth           => 2700;
use constant target_building        => ['Lacuna::DB::Result::Building::Observatory'];
use constant build_tags             => ['War'];

with "Lacuna::Role::Fleet::Send::Planet";
with "Lacuna::Role::Fleet::Send::Inhabited";
with "Lacuna::Role::Fleet::Send::NotIsolationist";
with "Lacuna::Role::Fleet::Send::IsHostile";
with "Lacuna::Role::Fleet::Arrive::TriggerDefense";
with "Lacuna::Role::Fleet::Arrive::DamageBuilding";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
