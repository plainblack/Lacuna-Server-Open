package Lacuna::DB::Result::Fleet::Galleon;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Trade',  level => 15 } ];
use constant base_food_cost         => 2500;
use constant base_water_cost        => 7500;
use constant base_energy_cost       => 25000;
use constant base_ore_cost          => 40200;
use constant base_time_cost         => 11200;
use constant base_waste_cost        => 3200;
use constant base_speed             => 1250;
use constant base_stealth           => 0;
use constant base_hold_size         => 1750;
use constant base_berth_level       => 10;
use constant pilotable              => 1;
use constant build_tags             => [qw(Trade Mining SupplyChain)];

with "Lacuna::Role::Fleet::Send::UsePush";
with "Lacuna::Role::Fleet::Arrive::CargoExchange";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
