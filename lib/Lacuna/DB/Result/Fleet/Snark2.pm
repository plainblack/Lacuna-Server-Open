package Lacuna::DB::Result::Fleet::Snark2;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::MunitionsLab',  level => 18 } ];
use constant base_food_cost         => 37000;
use constant base_water_cost        => 64600;
use constant base_energy_cost       => 194000;
use constant base_ore_cost          => 252230;
use constant base_time_cost         => 58400;
use constant base_waste_cost        => 59500;
use constant base_speed             => 1000;
use constant base_stealth           => 2600;
use constant base_combat            => 4000;
use constant base_hold_size         => 0;
use constant build_tags             => ['War'];
use constant type_formatted         => 'Snark II';
use constant splash_radius          => 1;

with "Lacuna::Role::Fleet::Send::Planet";
with "Lacuna::Role::Fleet::Send::Inhabited";
with "Lacuna::Role::Fleet::Send::NotIsolationist";
with "Lacuna::Role::Fleet::Send::IsHostile";
with "Lacuna::Role::Fleet::Arrive::TriggerDefense";
with "Lacuna::Role::Fleet::Arrive::DamageBuilding";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
