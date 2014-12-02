package Lacuna::DB::Result::Ships::SpyShuttle;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';
        
use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Espionage',  level => 15 } ];
use constant base_food_cost         => 750;
use constant base_water_cost        => 2300;
use constant base_energy_cost       => 15000;
use constant base_ore_cost          => 13000;
use constant base_time_cost         => 7200;
use constant base_waste_cost        => 5000;
use constant base_speed             => 2000;
use constant base_stealth           => 6200;
use constant base_hold_size         => 0;
use constant pilotable              => 1;
use constant build_tags             => ['Intelligence'];
use constant max_occupants          => 4;

with "Lacuna::Role::Ship::Send::NeutralArea";
with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::Inhabited";
with "Lacuna::Role::Ship::Send::NotIsolationist";
with "Lacuna::Role::Ship::Send::LoadWithSpies";
with "Lacuna::Role::Ship::Send::IsHostile";
with "Lacuna::Role::Ship::Arrive::CaptureWithSpies";
with "Lacuna::Role::Ship::Arrive::Orbit";
with "Lacuna::Role::Ship::Arrive::PickUpSpies";
with "Lacuna::Role::Ship::Arrive::CargoExchange";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
