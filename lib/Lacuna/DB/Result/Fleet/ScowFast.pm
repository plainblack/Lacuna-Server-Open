package Lacuna::DB::Result::Fleet::ScowFast;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [{ class=> 'Lacuna::DB::Result::Building::Waste::Sequestration',  level => 25 },
                                        { class=> 'Lacuna::DB::Result::Building::Propulsion',  level => 25 } ];
use constant base_food_cost         => 3000;
use constant base_water_cost        => 10000;
use constant base_energy_cost       => 100000;
use constant base_ore_cost          => 60000;
use constant base_time_cost         => 21600;
use constant base_waste_cost        => 25000;
use constant base_speed             => 700;
use constant base_combat            => 500;
use constant base_stealth           => 0;
use constant base_hold_size         => 2000;
use constant base_berth_level        => 20;
use constant build_tags             => [qw(War WasteChain)];

with "Lacuna::Role::Fleet::Send::PlanetAndStar";
with "Lacuna::Role::Fleet::Send::MaybeHostile";
with "Lacuna::Role::Fleet::Arrive::TriggerDefense";
with "Lacuna::Role::Fleet::Arrive::DumpWaste";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
