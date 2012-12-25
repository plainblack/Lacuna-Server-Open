package Lacuna::DB::Result::Fleet::HulkFast;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';


use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Trade',  level => 25 },
                                         { class=> 'Lacuna::DB::Result::Building::Propulsion',  level => 30 } ];
use constant base_food_cost         => 15000;
use constant base_water_cost        => 30000;
use constant base_energy_cost       => 500000;
use constant base_ore_cost          => 1000000;
use constant base_time_cost         => 43200;
use constant base_waste_cost        => 100000;
use constant base_speed             => 750;
use constant base_stealth           => 0;
use constant base_hold_size         => 10000;
use constant base_berth_level        => 25;
use constant pilotable              => 1;
use constant build_tags             => [qw(Trade Mining SupplyChain)];

with "Lacuna::Role::Fleet::Send::UsePush";
with "Lacuna::Role::Fleet::Arrive::CargoExchange";


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
