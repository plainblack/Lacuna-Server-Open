package Lacuna::DB::Result::Fleet::SpaceStation;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Embassy',  level => 20 } ];
use constant base_food_cost         => 8000000;
use constant base_water_cost        => 8000000;
use constant base_energy_cost       => 8000000;
use constant base_ore_cost          => 8000000;
use constant base_time_cost         => 60 * 60 * 72;
use constant base_waste_cost        => 1000000;
use constant base_speed             => 10;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant pilotable              => 1;
use constant build_tags             => [qw(War Intelligence)];
use constant type_formatted         => 'Space Station Hull';

with "Lacuna::Role::Ship::Send::Planet";
with 'Lacuna::Role::Ship::Send::Uninhabited';
with 'Lacuna::Role::Ship::Send::MemberOfAlliance';
with "Lacuna::Role::Ship::Send::SpendNextColonyCost";
with "Lacuna::Role::Ship::Send::IsHostile";
with "Lacuna::Role::Ship::Arrive::ConvertToStation";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
