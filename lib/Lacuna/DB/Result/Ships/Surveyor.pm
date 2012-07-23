package Lacuna::DB::Result::Ships::Surveyor;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Intelligence',  level => 10 } ];
use constant base_food_cost         => 1500;
use constant base_water_cost        => 2500;
use constant base_energy_cost       => 25000;
use constant base_ore_cost          => 29000;
use constant base_time_cost         => 60 * 60 * 6;
use constant base_waste_cost        => 5200;
use constant base_speed             => 3000;
use constant base_combat            => 1000;
use constant base_stealth           => 3000;
use constant base_hold_size         => 0;
use constant build_tags             => [qw(Exploration Intelligence)];

with "Lacuna::Role::Ship::Send::NeutralArea";
with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::MaybeHostile";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::SurveySurface";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
