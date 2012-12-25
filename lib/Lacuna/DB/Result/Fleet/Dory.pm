package Lacuna::DB::Result::Fleet::Dory;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Trade',  level => 1 } ];
use constant base_food_cost         => 350;
use constant base_water_cost        => 700;
use constant base_energy_cost       => 3250;
use constant base_ore_cost          => 5500;
use constant base_time_cost         => 3800;
use constant base_waste_cost        => 400;
use constant base_speed             => 1250;
use constant base_stealth           => 4100;
use constant base_hold_size         => 400;
use constant base_berth_level       => 1;
use constant pilotable              => 1;
use constant build_tags             => [qw(Trade Mining Intelligence SupplyChain)];

with "Lacuna::Role::Fleet::Send::UsePush";
with "Lacuna::Role::Fleet::Arrive::CaptureWithSpies";
with "Lacuna::Role::Fleet::Arrive::CargoExchange";
with "Lacuna::Role::Fleet::Arrive::PickUpSpies";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
