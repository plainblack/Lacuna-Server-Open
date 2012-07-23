package Lacuna::DB::Result::Ships::Scanner;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [{ class=> 'Lacuna::DB::Result::Building::Intelligence',  level => 5 }];
use constant base_food_cost         => 150;
use constant base_water_cost        => 250;
use constant base_energy_cost       => 2500;
use constant base_ore_cost          => 2900;
use constant base_time_cost         => 3600;
use constant base_waste_cost        => 520;
use constant base_speed             => 3000;
use constant base_combat            => 200;
use constant base_stealth           => 1850;
use constant base_hold_size         => 0;
use constant build_tags             => [qw(Exploration Intelligence)];

with "Lacuna::Role::Ship::Send::NeutralArea";
with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::MaybeHostile";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::ScanSurface";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
