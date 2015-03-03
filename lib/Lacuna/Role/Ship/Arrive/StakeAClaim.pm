package Lacuna::Role::Ship::Arrive::StakeAClaim;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # can't stake because it's already taken
    my $empire = $self->body->empire;
    my $planet = $self->foreign_body;
    my $claimed = 0;
    my $claimer_id = 0;
    my $claimed_by = 'Unknown';
    my $asteroid = 0;
    if ($planet->isa('Lacuna::DB::Result::Map::Body::Asteroid')) {
        $asteroid = 1;
    }
    elsif ($planet->is_locked) {
        $claimed = 1;
    }
    elsif ($planet->empire_id) {
        $claimed = 1;
        $claimer_id = $planet->empire_id;
        $claimed_by = $planet->empire->name;
    }
    elsif ($planet->is_claimed) {
        $claimed = 1;
        $claimer_id = $planet->is_claimed;
        $claimed_by = $planet->claimed_by->name;
    }
    if ($claimed) {
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'cannot_stake.txt',
            params      => [$self->name, $planet->x, $planet->y, $planet->name, $claimer_id, $claimed_by],
        );        
    }
    elsif ($asteroid) {
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'cannot_stake_asteroid.txt',
            params      => [$self->name, $planet->x, $planet->y, $planet->name],
        );
    }
    # let's claim this for our very own!
    else {
        $planet->claim($empire->id);
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'planet_claimed.txt',
            params      => [$planet->id, $planet->name, $planet->name],
        );
        $self->delete;
        confess [-1];
    }
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    my $empire = $self->body->empire;
    confess [1009, 'Can only be sent to habitable planets.'] if ($target->isa('Lacuna::DB::Result::Map::Body::Planet::GasGiant') && $empire->university_level < 19);
    confess [1009, 'Your species cannot survive on that planet.' ] if ($empire->university_level < 18 && ($target->orbit > $empire->max_orbit || $target->orbit < $empire->min_orbit));
    my $stake = Lacuna->cache->get('stake', $self->body->empire->id);
    confess [1010, 'You have already sent 3 stakes in a short period of time. Wait 24 hours since the last stake and send again.'] if (defined $stake && $stake >= 3);
    if ($target->star->station_id) {
        if ($target->star->station->laws->search({type => 'MembersOnlyColonization'})->count) {
            unless ($target->star->station->alliance_id == $self->body->empire->alliance_id) {
                confess [1010, 'Only '.$target->star->station->alliance->name.' members can colonize or stake planets in the jurisdiction of the space station.'];
            }
        }
    }
    return 1;
};

after send => sub {
    my $self = shift;
    Lacuna->cache->increment('stake', $self->body->empire_id, 1, 60 * 60 * 24);
};

1;
