package Lacuna::DB::Result::Ships::Scanner;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Intelligence',  level => 10 };
use constant base_food_cost      => 150;
use constant base_water_cost     => 250;
use constant base_energy_cost    => 2500;
use constant base_ore_cost       => 2900;
use constant base_time_cost      => 3600;
use constant base_waste_cost     => 520;
use constant base_speed     => 3000;
use constant base_stealth   => 1000;
use constant base_hold_size => 0;


sub arrive {
    my ($self) = @_;
    $self->delete;
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to planets.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Planet'));
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
