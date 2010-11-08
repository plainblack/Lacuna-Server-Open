package Lacuna::DB::Result::Ships::MiningPlatformShip;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';


use constant pilotable      => 1;

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Ore::Ministry',  level => 1 };
use constant base_food_cost      => 4800;
use constant base_water_cost     => 14400;
use constant base_energy_cost    => 96000;
use constant base_ore_cost       => 81600;
use constant base_time_cost      => 28800;
use constant base_waste_cost     => 12000;
use constant base_speed     => 600;
use constant base_stealth   => 0;
use constant base_hold_size => 0;


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Mining));
};

sub arrive {
    my ($self) = @_;
    if ($self->direction eq 'out') {
        my $body = $self->body;
        my $ministry = $body->mining_ministry;
        unless (defined $ministry) {
            $self->turn_around;
        }
        my $empire = $body->empire;
        my $foreign_body = $self->foreign_body;
        my $can = eval{$ministry->can_add_platform($foreign_body)};
        if ($can && !$@) {
            $ministry->add_platform($foreign_body)->update;
            $empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'mining_platform_deployed.txt',
                params      => [$body->id, $body->name, $foreign_body->x, $foreign_body->y, $foreign_body->name, $self->name],
            );
            $self->delete;
            my $type = ref $foreign_body;
            $type =~ s/^.*::(\w\d+)$/$1/;
            $empire->add_medal($type);
        }
        else {
            $self->turn_around;
            $empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'cannot_deploy_mining_platform.txt',
                params      => [$@->[1], $foreign_body->x, $foreign_body->y, $foreign_body->name, $body->id, $body->name, $self->name],
            );
        }
    }
    else {
        $self->land;
    }
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to asteroids.'] unless ($target->isa('Lacuna::DB::Result::Map::Body::Asteroid'));
    my $ministry = $self->body->mining_ministry;
    confess [1013, 'Cannot control platforms without a Mining Ministry.'] unless (defined $ministry);
    $ministry->can_add_platform($target);
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
