package Lacuna::DB::Result::Ships::ShortRangeColonyShip;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Observatory',  level => 3 };
use constant base_food_cost      => 15000;
use constant base_water_cost     => 15000;
use constant base_energy_cost    => 15000;
use constant base_ore_cost       => 15000;
use constant base_time_cost      => 60 * 60 * 8;
use constant base_waste_cost     => 7000;
use constant base_speed     => 10;
use constant base_stealth   => 0;
use constant base_hold_size => 0;
use constant pilotable      => 1;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Colonization));
};

sub arrive {
    my ($self) = @_;
    my $empire = $self->body->empire;
    if ($self->direction eq 'out') {
        my $planet = $self->foreign_body;
        if ($planet->is_locked || $planet->empire_id) {
            if (scalar keys %{$self->payload}) {
                unless ($self->capture_with_spies) {
                    $self->handle_cargo_exchange;
                }
            }
            else {
                $self->turn_around;
                $empire->send_predefined_message(
                    tags        => ['Alert'],
                    filename    => 'cannot_colonize.txt',
                    params      => [$planet->name, $planet->name],
                );
            }
        }
        else {
            $planet->lock;
            $planet->found_colony($empire);
            $empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'colony_founded.txt',
                params      => [$planet->name, $planet->name],
            );
            $empire->is_isolationist(0);
            $empire->update;
            $self->delete;
        }
    }
    else {
        $self->land;
    }
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to planets.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Planet'));
    confess [1013, 'Can only be sent to uninhabited planets.'] if ($target->empire_id);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
