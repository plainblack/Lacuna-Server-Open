package Lacuna::DB::Result::Ships::Scow;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Waste::Sequestration',  level => 10 };
use constant base_food_cost      => 2000;
use constant base_water_cost     => 5200;
use constant base_energy_cost    => 32400;
use constant base_ore_cost       => 28400;
use constant base_time_cost      => 14600;
use constant base_waste_cost     => 8400;
use constant base_speed     => 400;
use constant base_stealth   => 100;
use constant base_hold_size => 2100;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(War Trade));
};

sub arrive {
    my ($self) = @_;
    if ($self->foreign_star_id) {
        $self->delete;
    }
    else {
        unless ($self->trigger_defense) {
            my $body_attacked = $self->foreign_body;
            $body_attacked->add_waste($self->hold_size);
            $body_attacked->update;
            $self->body->empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'our_scow_hit.txt',
                params      => [$body_attacked->name, $self->hold_size],
            );
            $body_attacked->empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'hit_by_scow.txt',
                params      => [$self->body->empire_id, $self->body->empire->name, $body_attacked->name, $self->hold_size],
            );
            $body_attacked->add_news(30, sprintf('%s is so polluted that waste seems to be falling from the sky.', $body_attacked->name));
            $self->delete;
        }
    }
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to planets and stars.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Planet') || $target->isa('Lacuna::DB::Result::Map::Star'));
    confess [1013, 'Can only be sent to inhabited planets.'] if ($target->isa('Lacuna::DB::Result::Map::Body::Planet') && !$target->empire_id);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
