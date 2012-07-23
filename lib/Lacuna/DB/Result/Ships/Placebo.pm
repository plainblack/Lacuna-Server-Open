package Lacuna::DB::Result::Ships::Placebo;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

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

with "Lacuna::Role::Ship::Send::NeutralArea";
with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::Inhabited";
with "Lacuna::Role::Ship::Send::NotIsolationist";
with "Lacuna::Role::Ship::Send::IsHostile";
with "Lacuna::Role::Ship::Arrive::Scuttle";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
