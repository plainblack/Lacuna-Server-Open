package Lacuna::DB::Result::Ships::SmugglerShip;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';
        
use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Propulsion',  level => 1 };
use constant food_cost      => 1500;
use constant water_cost     => 3900;
use constant energy_cost    => 27000;
use constant ore_cost       => 16800;
use constant time_cost      => 28800;
use constant waste_cost     => 1800;
use constant base_speed     => 1500;
use constant base_stealth   => 8000;
use constant base_hold_size => 480;
use constant pilotable      => 1;


sub arrive {
    my ($self) = @_;
    my $captured = $self->capture_with_spies(1) if (exists $self->payload->{spies} || exists $self->payload->{fetch_spies} );
    unless ($captured) {
        $self->handle_cargo_exchange;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
