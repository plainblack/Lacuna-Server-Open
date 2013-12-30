package Lacuna::DB::Result::Ships::SecurityMinistrySeeker;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::MunitionsLab',  level => 20 } ];
use constant base_food_cost         => 20000;
use constant base_water_cost        => 50000;
use constant base_energy_cost       => 180000;
use constant base_ore_cost          => 200000;
use constant base_time_cost         => 58500;
use constant base_waste_cost        => 40000;
use constant base_speed             => 1000;
use constant base_combat            => 3500;
use constant base_stealth           => 2700;
use constant target_building        => ['Lacuna::DB::Result::Building::Security',
                                        'Lacuna::DB::Result::Building::Module::PoliceStation',
                                        'Lacuna::DB::Result::Building::Permanent::GratchsGauntlet',
                                       ];
use constant build_tags             => ['War'];

with "Lacuna::Role::Ship::Send::NeutralArea";
with "Lacuna::Role::Ship::Send::Planet";
with "Lacuna::Role::Ship::Send::Inhabited";
with "Lacuna::Role::Ship::Send::NotIsolationist";
with "Lacuna::Role::Ship::Send::IsHostile";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::DamageBuilding";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
