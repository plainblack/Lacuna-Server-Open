package Lacuna::DB::Result::Ships::CargoShip;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Trade',  level => 10 };
use constant base_food_cost      => 1200;
use constant base_water_cost     => 3600;
use constant base_energy_cost    => 12000;
use constant base_ore_cost       => 20400;
use constant base_time_cost      => 7200;
use constant base_waste_cost     => 1500;
use constant base_speed     => 1000;
use constant base_stealth   => 4000;
use constant base_hold_size => 1555;
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
