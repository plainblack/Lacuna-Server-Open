package Lacuna::Role::Ship::Arrive::ConvertToStation;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # can't convert because it's already taken
    my $empire = $self->body->empire;
    my $planet = $self->foreign_body;
    if ($planet->is_locked || $planet->empire_id) {
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'cannot_convert_to_station.txt',
            params      => [$planet->x, $planet->y, $planet->name, $planet->name],
        );
    }
    
    # can't convert because it's claimed
    elsif ($planet->is_claimed && $planet->is_claimed != $empire->id) {
        my $claimer = $planet->claimed_by;
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'cannot_convert_to_station_staked.txt',
            params      => [$planet->x, $planet->y, $planet->name, $claimer->id, $claimer->name, $planet->name],
        );        
    }
    
    # can't convert because not in an alliance
    elsif (!$empire->alliance_id) {
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'cannot_convert_to_station_no_alliance.txt',
            params      => [$planet->x, $planet->y, $planet->name, $planet->name],
        );
    }
    
    # let's claim this for our very own!
    else {
        $planet->lock;
        $planet->convert_to_station($empire);
        $empire->send_predefined_message(
            tags        => ['Colonization','Alert'],
            filename    => 'station_founded.txt',
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
    if ($target->star->station_id) {
        if ($target->star->station->laws->search({type => 'MembersOnlyStations'})->count) {
            unless ($target->star->station->alliance_id == $self->body->empire->alliance_id) {
                confess [1010, 'Only '.$target->star->station->alliance->name.' members can setup stations in the jurisdiction of the space station.'];
            }
        }
    }
    return 1;
};

1;
