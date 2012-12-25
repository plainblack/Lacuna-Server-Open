package Lacuna::DB::Result::Fleet::Fighter;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::PilotTraining',  level => 1 } ];
use constant base_food_cost         => 1000;
use constant base_water_cost        => 2600;
use constant base_energy_cost       => 16200;
use constant base_ore_cost          => 14200;
use constant base_time_cost         => 60 * 60 * 4;
use constant base_waste_cost        => 4200;
use constant base_combat            => 4000;
use constant base_speed             => 2000;
use constant pilotable              => 1;
use constant build_tags             => ['War'];

with "Lacuna::Role::Fleet::Send::Body";
with "Lacuna::Role::Fleet::Send::RecallWhileTravelling";
with "Lacuna::Role::Fleet::Send::ScuttleWhileTravelling";
with "Lacuna::Role::Fleet::Arrive::Defend";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
