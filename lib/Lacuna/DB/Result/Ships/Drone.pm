package Lacuna::DB::Result::Ships::Drone;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Security',  level => 1 };
use constant food_cost      => 250;
use constant water_cost     => 650;
use constant energy_cost    => 4050;
use constant ore_cost       => 3550;
use constant time_cost      => 3650;
use constant waste_cost     => 1050;
use constant base_speed     => 0;
use constant base_stealth   => 0;
use constant base_hold_size => 0;


sub arrive {
    my ($self) = @_;
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
