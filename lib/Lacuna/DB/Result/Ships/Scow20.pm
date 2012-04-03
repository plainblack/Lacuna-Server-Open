package Lacuna::DB::Result::Ships::Scow20;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => { class=> 'Lacuna::DB::Result::Building::Waste::Sequestration',  level => 20 };
use constant base_food_cost         =>  10000;
use constant base_water_cost        =>  30000;
use constant base_energy_cost       => 150000;
use constant base_ore_cost          => 100000;
use constant base_time_cost         =>  28800;
use constant base_waste_cost        =>  50000;
use constant base_speed             => 350;
use constant base_combat            => 600;
use constant base_stealth           => 0;
use constant base_hold_size         => 10000;
use constant base_berth_size         => 15;
use constant build_tags             => [qw(War Trade)];

with "Lacuna::Role::Ship::Send::PlanetAndStar";
with "Lacuna::Role::Ship::Send::MaybeHostile";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::DumpWaste";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
