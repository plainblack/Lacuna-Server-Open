package Lacuna::DB::Result::Fleet::Barge;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Trade',  level => 5 } ];
use constant base_food_cost         => 650;
use constant base_water_cost        => 1900;
use constant base_energy_cost       => 6100;
use constant base_ore_cost          => 10300;
use constant base_time_cost         => 5000;
use constant base_waste_cost        => 900;
use constant base_speed             => 1100;
use constant base_stealth           => 2450;
use constant base_hold_size         => 800;
use constant base_berth_level       => 1;
use constant pilotable              => 1;
use constant build_tags             => [qw(Trade Mining Intelligence SupplyChain)];

with "Lacuna::Role::Fleet::Send::UsePush";
with "Lacuna::Role::Fleet::Arrive::CaptureWithSpies";
with "Lacuna::Role::Fleet::Arrive::CargoExchange";
with "Lacuna::Role::Fleet::Arrive::PickUpSpies";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
