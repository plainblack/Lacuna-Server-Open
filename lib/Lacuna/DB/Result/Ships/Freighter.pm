package Lacuna::DB::Result::Ships::Freighter;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';


use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Trade',  level => 20 };
use constant food_cost      => 3600;
use constant water_cost     => 10800;
use constant energy_cost    => 36000;
use constant ore_cost       => 61000;
use constant time_cost      => 15000;
use constant waste_cost     => 4800;
use constant base_speed     => 800;
use constant base_stealth   => 1000;
use constant base_hold_size => 1905;
use constant pilotable      => 1;

sub arrive {
    my ($self) = @_;
    my $captured = $self->capture_with_spies(2) if (exists $self->payload->{spies} || exists $self->payload->{fetch_spies} );
    unless ($captured) {
        $self->handle_cargo_exchange;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
