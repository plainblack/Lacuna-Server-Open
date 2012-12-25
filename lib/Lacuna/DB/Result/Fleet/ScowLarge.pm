package Lacuna::DB::Result::Fleet::ScowLarge;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Waste::Sequestration',  level => 20 } ];
use constant base_food_cost         =>  10000;
use constant base_water_cost        =>  32000;
use constant base_energy_cost       => 170000;
use constant base_ore_cost          => 120000;
use constant base_time_cost         =>  32000;
use constant base_waste_cost        =>  50000;
use constant base_speed             => 325;
use constant base_combat            => 600;
use constant base_stealth           => 0;
use constant base_hold_size         => 12000;
use constant base_berth_level       => 15;
use constant build_tags             => [qw(War WasteChain)];

with "Lacuna::Role::Fleet::Send::PlanetAndStar";
with "Lacuna::Role::Fleet::Send::MaybeHostile";
with "Lacuna::Role::Fleet::Arrive::TriggerDefense";
with "Lacuna::Role::Fleet::Arrive::DumpWaste";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
