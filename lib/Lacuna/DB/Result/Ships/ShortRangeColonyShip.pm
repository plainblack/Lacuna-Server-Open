package Lacuna::DB::Result::Ships::ShortRangeColonyShip;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Observatory',  level => 3 } ];
use constant base_food_cost         => 15000;
use constant base_water_cost        => 15000;
use constant base_energy_cost       => 15000;
use constant base_ore_cost          => 15000;
use constant base_time_cost         => 60 * 60 * 8;
use constant base_waste_cost        => 7000;
use constant base_combat            => 1000;
use constant base_speed             => 1000;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant pilotable              => 1;
use constant build_tags             => ['Colonization'];

with "Lacuna::Role::Ship::Send::Range";
with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::Uninhabited";
with "Lacuna::Role::Ship::Send::StarterZone";
with "Lacuna::Role::Ship::Send::SpendNextColonyCost";
with "Lacuna::Role::Ship::Send::IsHostile";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::Colonize";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
