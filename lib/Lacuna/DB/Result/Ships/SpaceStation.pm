package Lacuna::DB::Result::Ships::SpaceStation;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';


use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Embassy',  level => 20 };
use constant food_cost      => 108000;
use constant water_cost     => 270000;
use constant energy_cost    => 400000;
use constant ore_cost       => 540000;
use constant time_cost      => 86400;
use constant waste_cost     => 136900;
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
