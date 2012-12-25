package Lacuna::DB::Result::Fleet::Hulk;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';


use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Trade',  level => 25 }];
use constant base_food_cost         => 7300;
use constant base_water_cost        => 23000;
use constant base_energy_cost       => 75000;
use constant base_ore_cost          => 124000;
use constant base_time_cost         => 20000;
use constant base_waste_cost        => 11000;
use constant base_speed             => 600;
use constant base_stealth           => 0;
use constant base_hold_size         => 7900;
use constant base_berth_level       => 20;
use constant pilotable              => 1;
use constant build_tags             => [qw(Trade Mining SupplyChain)];

with "Lacuna::Role::Fleet::Send::UsePush";
with "Lacuna::Role::Fleet::Arrive::CargoExchange";


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
