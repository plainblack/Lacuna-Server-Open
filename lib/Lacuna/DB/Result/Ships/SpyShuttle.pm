package Lacuna::DB::Result::Ships::SpyShuttle;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';
        
use constant prereq         => { class=> 'Lacuna::DB::Result::Building::University',  level => 99 };
use constant food_cost      => 1000;
use constant water_cost     => 3000;
use constant energy_cost    => 20000;
use constant ore_cost       => 17000;
use constant time_cost      => 7200;
use constant waste_cost     => 5000;
use constant base_speed     => 2000;
use constant base_stealth   => 9000;
use constant base_hold_size => 0;
use constant pilotable      => 1;

sub arrive {
    my ($self) = @_;
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
