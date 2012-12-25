package Lacuna::DB::Result::Fleet::GasGiantSettlementPlatformShip;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::GasGiantLab',  level => 1 } ];
use constant base_food_cost         => 36000;
use constant base_water_cost        => 90000;
use constant base_energy_cost       => 340000;
use constant base_ore_cost          => 250000;
use constant base_time_cost         => 48000;
use constant base_waste_cost        => 53000;
use constant base_speed             => 500;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant pilotable              => 1;
use constant build_tags             => ['Colonization']; 

with "Lacuna::Role::Fleet::Send::GasGiant";
with "Lacuna::Role::Fleet::Arrive::AddGasGiantPlatform";


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
