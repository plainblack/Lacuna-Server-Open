package Lacuna::DB::Result::Fleet::TerraformingPlatformShip;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::TerraformingLab',  level => 1 } ];
use constant base_food_cost         => 96000;
use constant base_water_cost        => 180000;
use constant base_energy_cost       => 310000;
use constant base_ore_cost          => 226000;
use constant base_time_cost         => 45000;
use constant base_waste_cost        => 45000;
use constant base_speed             => 550;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant pilotable              => 1;
use constant build_tags             => ['Colonization'];

with "Lacuna::Role::Fleet::Send::Planet";
with "Lacuna::Role::Fleet::Arrive::AddTerraformingPlatform";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
