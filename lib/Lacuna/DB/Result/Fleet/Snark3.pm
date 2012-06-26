package Lacuna::DB::Result::Fleet::Snark3;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::MunitionsLab',  level => 25 } ];
use constant base_food_cost         => 47000;
use constant base_water_cost        => 84600;
use constant base_energy_cost       => 224000;
use constant base_ore_cost          => 352230;
use constant base_time_cost         => 58400;
use constant base_waste_cost        => 69500;
use constant base_speed             => 1000;
use constant base_stealth           => 3000;
use constant base_combat            => 5000;
use constant base_hold_size         => 0;
use constant build_tags             => ['War'];
use constant type_formatted         => 'Snark III';
use constant splash_radius          => 2;

with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::Inhabited";
with "Lacuna::Role::Ship::Send::NotIsolationist";
with "Lacuna::Role::Ship::Send::IsHostile";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::DamageBuilding";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
