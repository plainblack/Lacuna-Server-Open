package Lacuna::DB::Result::Ships::AttackGroup;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::University',  level => 35 } ];
use constant base_food_cost         => 1_000_000_000_000;
use constant base_water_cost        => 1_000_000_000_000;
use constant base_energy_cost       => 1_000_000_000_000;
use constant base_ore_cost          => 1_000_000_000_000;
use constant base_time_cost         => 120 * 24 * 60 * 60;
use constant base_waste_cost        => 39600;
use constant base_speed             => 0;
use constant base_stealth           => 0;
use constant base_combat            => 0;
use constant base_hold_size         => 0;
use constant build_tags             => ['Kludge'];

with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::DamageBuilding";
with "Lacuna::Role::Ship::Arrive::DumpWaste";
with "Lacuna::Role::Ship::Arrive::DeployBleeder";
with "Lacuna::Role::Ship::Arrive::DeploySmolderingCrater";
with "Lacuna::Role::Ship::Arrive::ScanSurface";
with "Lacuna::Role::Ship::Arrive::SurveySurface";
with "Lacuna::Role::Ship::Arrive::DestroyMinersExcavators";
with "Lacuna::Role::Ship::Arrive::GroupHome";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
