package Lacuna::DB::Result::Ships::Scanner;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Intelligence',  level => 5 };
use constant base_food_cost      => 150;
use constant base_water_cost     => 250;
use constant base_energy_cost    => 2500;
use constant base_ore_cost       => 2900;
use constant base_time_cost      => 3600;
use constant base_waste_cost     => 520;
use constant base_speed     => 3000;
use constant base_stealth   => 3700;
use constant base_hold_size => 0;


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Exploration Intelligence));
};

sub arrive {
    my ($self) = @_;
    unless ($self->trigger_defense) {
        my $body_attacked = $self->foreign_body;
        my @map;
        my $buildings = $body_attacked->buildings;
        while (my $building = $buildings->next) {
            push @map, {
                image   => $building->image_level,
                x       => $building->x,
                y       => $building->y,
            };
        }
        $self->body->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'scanner_data.txt',
            params      => [$body_attacked->x, $body_attacked->y, $body_attacked->name],
            attachments  => {
                map => {
                    surface         => $body_attacked->surface,
                    buildings       => \@map
                }
            },
        );
        if ($body_attacked->empire_id && defined $body_attacked->empire) {
            $body_attacked->empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'we_were_scanned.txt',
                params      => [$body_attacked->id, $body_attacked->name, $self->body->empire_id, $self->body->empire->name],
            );
            $body_attacked->add_news(65, sprintf('Several people reported seeing a UFO in the %s sky today.', $body_attacked->name));
        }
        $self->delete;
    }
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to planets.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Planet'));
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
