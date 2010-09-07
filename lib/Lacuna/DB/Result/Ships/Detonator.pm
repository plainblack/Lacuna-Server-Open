package Lacuna::DB::Result::Ships::Detonator;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';


use constant prereq         => { class=> 'Lacuna::DB::Result::Building::DemolitionLab',  level => 1 };
use constant base_food_cost      => 6000;
use constant base_water_cost     => 15600;
use constant base_energy_cost    => 97200;
use constant base_ore_cost       => 113600;
use constant base_time_cost      => 29200;
use constant base_waste_cost     => 25200;
use constant base_speed     => 1000;
use constant base_stealth   => 2000;
use constant base_hold_size => 0;


sub arrive {
    my ($self) = @_;
    $self->delete;
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to stars or asteroids.'] unless ($target->isa('Lacuna::DB::Result::Map::Star') || $target->isa('Lacuna::DB::Result::Map::Body::Asteroid') );
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
