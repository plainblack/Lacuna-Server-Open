package Lacuna::DB::Result::Ships::SpyShuttle;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';
        
use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Espionage',  level => 15 };
use constant base_food_cost      => 750;
use constant base_water_cost     => 2300;
use constant base_energy_cost    => 15000;
use constant base_ore_cost       => 13000;
use constant base_time_cost      => 7200;
use constant base_waste_cost     => 5000;
use constant base_speed     => 2000;
use constant base_stealth   => 9000;
use constant base_hold_size => 0;
use constant pilotable      => 1;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Intelligence));
};

sub arrive {
    my ($self) = @_;
    unless ($self->capture_with_spies) {
        $self->delete;
    }
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to planets.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Planet'));
    confess [1013, 'Can only be sent to inhabited planets.'] unless ($target->empire_id);
    confess [1013, sprintf('%s is an isolationist empire, and must be left alone.',$target->empire->name)] if $target->empire->is_isolationist;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
