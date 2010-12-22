package Lacuna::Role::Ship::Arrive::Colonize;

use strict;
use Moose::Role;

after turn_around => sub {
    my $self = shift;
    $self->body->add_happiness($self->payload->{colony_cost})->update;
};

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # can't colonize because it's already taken
    my $empire = $self->body->empire;
    my $planet = $self->foreign_body;
    if ($planet->is_locked || $planet->empire_id) {
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'cannot_colonize.txt',
            params      => [$planet->x, $planet->y, $planet->name, $planet->name],
        );
    }
    
    # can't colonize because it's claimed
    elsif ($planet->is_claimed && $planet->is_claimed != $empire->id) {
        my $claimer = $planet->claimed_by;
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'cannot_colonize_staked.txt',
            params      => [$planet->x, $planet->y, $planet->name, $claimer->id, $claimer->name, $planet->name],
        );        
    }
    
    # let's claim this for our very own!
    else {
        $planet->lock;
        $planet->found_colony($empire);
        $empire->send_predefined_message(
            tags        => ['Alert'],
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
    my $next_colony_cost = $empire->next_colony_cost;
    confess [ 1011, 'You do not have enough happiness to colonize another planet. You need '.$next_colony_cost.' happiness.', [$next_colony_cost]] unless ( $self->body->happiness > $next_colony_cost);
    return 1;
};

after send => sub {
    my $self = shift;
    my $next_colony_cost = $self->body->empire->next_colony_cost(-1);
    $self->body->spend_happiness($next_colony_cost)->update;
    $self->payload({ colony_cost => $next_colony_cost });
    $self->update;
};

1;
