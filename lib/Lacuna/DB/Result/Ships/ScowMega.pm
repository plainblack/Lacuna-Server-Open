package Lacuna::DB::Result::Ships::ScowMega;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Waste::Sequestration',  level => 30 } ];
use constant base_food_cost         =>   60000;
use constant base_water_cost        =>  180000;
use constant base_energy_cost       => 6000000;
use constant base_ore_cost          => 1500000;
use constant base_time_cost         => 98000;
use constant base_waste_cost        => 25000000;
use constant base_speed             => 100;
use constant base_combat            => 0;
use constant base_stealth           => 0;
use constant base_hold_size         => 300000;
use constant base_berth_level       => 25;
use constant build_tags             => [qw(War WasteChain)];

with "Lacuna::Role::Ship::Send::NeutralArea";
with "Lacuna::Role::Ship::Send::PlanetAndStar";
with "Lacuna::Role::Ship::Send::MaybeHostile";
with "Lacuna::Role::Ship::Arrive::TriggerDefense";
with "Lacuna::Role::Ship::Arrive::DumpWaste";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
