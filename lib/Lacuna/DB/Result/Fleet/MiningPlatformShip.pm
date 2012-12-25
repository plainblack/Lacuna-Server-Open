package Lacuna::DB::Result::Fleet::MiningPlatformShip;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Ore::Ministry',  level => 1 }];
use constant base_food_cost         => 4800;
use constant base_water_cost        => 14400;
use constant base_energy_cost       => 96000;
use constant base_ore_cost          => 81600;
use constant base_time_cost         => 28800;
use constant base_waste_cost        => 12000;
use constant base_combat            => 600;
use constant base_speed             => 600;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant pilotable              => 1;
use constant build_tags             => ['Mining'];

with "Lacuna::Role::Fleet::Send::Asteroid";
with "Lacuna::Role::Fleet::Arrive::TriggerDefense";
with "Lacuna::Role::Fleet::Arrive::DeployMiningPlatform";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
