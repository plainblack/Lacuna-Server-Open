package Lacuna::DB::Result::Ships::SpyPod;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';
        
use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Espionage',  level => 1 };
use constant food_cost      => 200;
use constant water_cost     => 600;
use constant energy_cost    => 4000;
use constant ore_cost       => 3400;
use constant time_cost      => 3600;
use constant waste_cost     => 1000;
use constant base_speed     => 2000;
use constant base_stealth   => 10000;
use constant base_hold_size => 0;
use constant pilotable      => 1;

sub arrive {
    my ($self) = @_;
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
