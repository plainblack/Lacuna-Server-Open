package Lacuna::DB::Result::Fleet::Drone;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Fleet';

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::Security',  level => 1 } ];
use constant base_food_cost         => 250;
use constant base_water_cost        => 650;
use constant base_energy_cost       => 4050;
use constant base_ore_cost          => 3550;
use constant base_time_cost         => 3650;
use constant base_waste_cost        => 1050;
use constant base_speed             => 0;
use constant base_combat            => 6000;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant build_tags             => ['War'];

with "Lacuna::Role::Fleet::Send::NotAllowed";

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
