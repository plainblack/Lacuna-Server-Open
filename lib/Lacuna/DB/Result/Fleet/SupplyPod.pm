package Lacuna::DB::Result::Fleet::SupplyPod;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::PlanetaryCommand',  level => 10 } ];
use constant base_food_cost         => 1800;
use constant base_water_cost        => 1900;
use constant base_energy_cost       => 4500;
use constant base_ore_cost          => 4500;
use constant base_time_cost         => 60 * 60 * 2; 
use constant base_waste_cost        => 5000;
use constant base_speed             => 1000;
use constant base_stealth           => 0;
use constant base_hold_size         => 400;
use constant pilotable              => 0;
use constant build_tags             => [qw(Colonization)];
use constant supply_pod_level       => 5;

with "Lacuna::Role::Fleet::Send::Planet";
with "Lacuna::Role::Fleet::Send::Inhabited";
with "Lacuna::Role::Fleet::Send::LoadSupplyPod";
with "Lacuna::Role::Fleet::Arrive::DeploySupplyPod";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
