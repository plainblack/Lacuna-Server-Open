package Lacuna::DB::Result::Fleet::Freighter;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';


use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Trade',  level => 20 } ];
use constant base_food_cost         => 3600;
use constant base_water_cost        => 10800;
use constant base_energy_cost       => 36000;
use constant base_ore_cost          => 61000;
use constant base_time_cost         => 15000;
use constant base_waste_cost        => 4800;
use constant base_speed             => 900;
use constant base_stealth           => 0;
use constant base_hold_size         => 4000;
use constant base_berth_level       => 15;
use constant pilotable              => 1;
use constant build_tags             => [qw(Trade Mining SupplyChain)];

with "Lacuna::Role::Fleet::Send::UsePush";
with "Lacuna::Role::Fleet::Arrive::CargoExchange";


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
