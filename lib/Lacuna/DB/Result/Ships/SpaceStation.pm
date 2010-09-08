package Lacuna::DB::Result::Ships::SpaceStation;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';


use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Embassy',  level => 20 };
use constant base_food_cost      => 108000;
use constant base_water_cost     => 270000;
use constant base_energy_cost    => 500000;
use constant base_ore_cost       => 2000000;
use constant base_time_cost      => 259200;
use constant base_waste_cost     => 136900;
use constant base_speed     => 15;
use constant base_stealth   => 0;
use constant base_hold_size => 0;
use constant pilotable      => 1;


sub arrive {
    my ($self) = @_;
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
