package Lacuna::DB::Result::Fleet::Placebo;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [{ class=> 'Lacuna::DB::Result::Building::CloakingLab',  level => 5 }];
use constant base_food_cost         => 2000;
use constant base_water_cost        => 2000;
use constant base_energy_cost       => 4000;
use constant base_ore_cost          => 4000;
use constant base_time_cost         => 3600;
use constant base_waste_cost        => 400;
use constant base_speed             => 500;
use constant base_combat            => 0;
use constant base_stealth           => 2500;
use constant base_hold_size         => 0;
use constant build_tags             => [qw(War)];

with "Lacuna::Role::Fleet::Send::Planet";
with "Lacuna::Role::Fleet::Send::Inhabited";
with "Lacuna::Role::Fleet::Send::NotIsolationist";
with "Lacuna::Role::Fleet::Send::IsHostile";
with "Lacuna::Role::Fleet::Arrive::Scuttle";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
