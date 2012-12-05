package Lacuna::DB::Result::Ships::FissureSealer;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Observatory',  level => 15 } ];
use constant base_food_cost         =>  15_000;
use constant base_water_cost        =>  30_000;
use constant base_energy_cost       =>  90_000;
use constant base_ore_cost          => 100_000;
use constant base_time_cost         => 60 * 60 * 24 * 2;
use constant base_waste_cost        => 50_000;
use constant base_combat            => 0;
use constant base_speed             => 250;
use constant base_stealth           => 0;
use constant base_hold_size         => 100_000;
use constant pilotable              => 0;
use constant build_tags             => ['Exploration'];

with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::Uninhabited";
with "Lacuna::Role::Ship::Arrive::SealFissure";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
