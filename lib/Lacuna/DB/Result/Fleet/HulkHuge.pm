package Lacuna::DB::Result::Fleet::HulkHuge;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';


use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Trade',  level => 30 } ];
use constant base_food_cost         => 90000;
use constant base_water_cost        => 150000;
use constant base_energy_cost       => 15000000;
use constant base_ore_cost          => 10000000;
use constant base_time_cost         => 256000;
use constant base_waste_cost        => 1000000;
use constant base_speed             => 350;
use constant base_stealth           => 0;
use constant base_hold_size         => 170100;
use constant base_berth_level       => 30;
use constant pilotable              => 1;
use constant build_tags             => [qw(Trade Mining SupplyChain)];

with "Lacuna::Role::Ship::Send::UsePush";
with "Lacuna::Role::Ship::Arrive::CargoExchange";


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
