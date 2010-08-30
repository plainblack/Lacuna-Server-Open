package Lacuna::DB::Result::Ships::Scow;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Waste::Sequestration',  level => 15 };
use constant food_cost      => 2000;
use constant water_cost     => 5200;
use constant energy_cost    => 32400;
use constant ore_cost       => 28400;
use constant time_cost      => 14600;
use constant waste_cost     => 8400;
use constant base_speed     => 900;
use constant base_stealth   => 100;
use constant base_hold_size => 1000;


sub arrive {
    my ($self) = @_;
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
