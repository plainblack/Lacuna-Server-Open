package Lacuna::DB::Result::Ships::SupplyPod4;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::PlanetaryCommand',  level => 25 } ];
use constant base_food_cost         => 8000000;
use constant base_water_cost        => 8500000;
use constant base_energy_cost       => 20000000;
use constant base_ore_cost          => 20000000;
use constant base_time_cost         => 60 * 60 * 8; 
use constant base_waste_cost        => 2000000;
use constant base_speed             => 1250;
use constant base_stealth           => 0;
use constant base_hold_size         => 3800;
use constant pilotable              => 0;
use constant build_tags             => [qw(Colonization)];
use constant image_subdir => 'v2';
use constant supply_pod_level       => 20;
use constant type_formatted         => 'Supply Pod IV';

with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::Inhabited";
with "Lacuna::Role::Ship::Send::LoadSupplyPod";
with "Lacuna::Role::Ship::Arrive::DeploySupplyPod";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
