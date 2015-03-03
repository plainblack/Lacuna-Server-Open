package Lacuna::DB::Result::Ships::SupplyPod5;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::PlanetaryCommand',  level => 30 } ];
use constant base_food_cost         => 16000000;
use constant base_water_cost        => 17000000;
use constant base_energy_cost       => 40000000;
use constant base_ore_cost          => 40000000;
use constant base_time_cost         => 60 * 60 * 16; 
use constant base_waste_cost        => 5000000;
use constant base_speed             => 1000;
use constant base_stealth           => 0;
use constant base_hold_size         => 7000;
use constant pilotable              => 0;
use constant build_tags             => [qw(Colonization)];
use constant supply_pod_level       => 25;
use constant type_formatted         => 'Supply Pod V';

with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::Inhabited";
with "Lacuna::Role::Ship::Send::LoadSupplyPod";
with "Lacuna::Role::Ship::Arrive::DeploySupplyPod";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
