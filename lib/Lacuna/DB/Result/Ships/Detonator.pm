package Lacuna::DB::Result::Ships::Detonator;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';


use constant prereq         => { class=> 'Lacuna::DB::Result::Building::University',  level => 99 };
use constant food_cost      => 6000;
use constant water_cost     => 15600;
use constant energy_cost    => 97200;
use constant ore_cost       => 113600;
use constant time_cost      => 29200;
use constant waste_cost     => 25200;
use constant base_speed     => 1000;
use constant base_stealth   => 2000;
use constant base_hold_size => 0;


sub arrive {
    my ($self) = @_;
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
