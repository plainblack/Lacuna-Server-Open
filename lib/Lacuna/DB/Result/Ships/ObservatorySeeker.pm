package Lacuna::DB::Result::Ships::ObservatorySeeker;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::University',  level => 99 };
use constant base_food_cost      => 20000;
use constant base_water_cost     => 50000;
use constant base_energy_cost    => 300000;
use constant base_ore_cost       => 350000;
use constant base_time_cost      => 58500;
use constant base_waste_cost     => 80000;
use constant base_speed     => 1000;
use constant base_stealth   => 2000;

sub arrive {
    my ($self) = @_;
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
