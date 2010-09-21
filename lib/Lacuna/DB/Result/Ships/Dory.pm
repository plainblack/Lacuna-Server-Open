package Lacuna::DB::Result::Ships::Dory;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Trade',  level => 1 };
use constant base_food_cost      => 700;
use constant base_water_cost     => 1400;
use constant base_energy_cost    => 6500;
use constant base_ore_cost       => 11000;
use constant base_time_cost      => 3800;
use constant base_waste_cost     => 800;
use constant base_speed     => 1200;
use constant base_stealth   => 5000;
use constant base_hold_size => 385;
use constant pilotable      => 1;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Trade Mining Intelligence));
};

sub arrive {
    my ($self) = @_;
    unless ($self->capture_with_spies) {
        $self->handle_cargo_exchange;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
