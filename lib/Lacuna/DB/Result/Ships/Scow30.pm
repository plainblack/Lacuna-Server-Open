package Lacuna::DB::Result::Ships::Scow30;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => { class=> 'Lacuna::DB::Result::Building::Waste::Sequestration',  level => 30 };
use constant base_food_cost         =>   50000;
use constant base_water_cost        =>  150000;
use constant base_energy_cost       => 5000000;
use constant base_ore_cost          => 1000000;
use constant base_time_cost         => 86400;
use constant base_waste_cost        => 20000000;
use constant base_speed             => 100;
use constant base_combat            => 0;
use constant base_stealth           => 0;
use constant base_hold_size         => 200000;
use constant base_dock_size         => 25;
use constant build_tags             => [qw(War Trade)];

with "Lacuna::Role::Ship::Send::PlanetAndStar";
with "Lacuna::Role::Ship::Send::MaybeHostile";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::DumpWaste";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
