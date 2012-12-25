package Lacuna::Role::Ship::Arrive::Colonize;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # can't colonize because it's already taken
    my $empire = $self->body->empire;
    my $planet = $self->foreign_body;

    if ($planet->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant') && $empire->university_level < 19) {
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'cannot_colonize_gg.txt',
            params      => [$planet->x, $planet->y, $planet->name, $planet->name],
        );
    }
    elsif ($planet->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'cannot_colonize_asteroid.txt',
            params      => [$planet->x, $planet->y, $planet->name, $planet->name],
        );
    }
    elsif ($planet->is_locked || $planet->empire_id) {
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'cannot_colonize.txt',
            params      => [$planet->x, $planet->y, $planet->name, $planet->name],
        );
    }
    
    # can't colonize because it's claimed
    elsif ($planet->is_claimed && $planet->is_claimed != $empire->id) {
        my $claimer = $planet->claimed_by;
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'cannot_colonize_staked.txt',
            params      => [$planet->x, $planet->y, $planet->name, $claimer->id, $claimer->name, $planet->name],
        );        
    }
    
    # let's claim this for our very own!
    else {
        $planet->lock;
        $planet->found_colony($empire);
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'colony_founded.txt',
            params      => [$planet->id, $planet->name, $planet->name],
        );
        $empire->is_isolationist(0);
        $empire->update;
        $self->delete;
        confess [-1];
    }
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    my $empire = $self->body->empire;
    confess [1009, 'Can only be sent to habitable planets.'] if ($target->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant') && $empire->university_level < 19);
    confess [ 1009, 'Your species cannot survive on that planet.' ] if ($empire->university_level < 18 && ($target->orbit > $empire->max_orbit || $target->orbit < $empire->min_orbit));
    if ($target->star->station_id) {
        if ($target->star->station->laws->search({type => 'MembersOnlyColonization'})->count) {
            unless ($target->star->station->alliance_id == $self->body->empire->alliance_id) {
                confess [1010, 'Only '.$target->star->station->alliance->name.' members can colonize planets in the jurisdiction of the space station.'];
            }
        }
    }
    return 1;
};

1;
