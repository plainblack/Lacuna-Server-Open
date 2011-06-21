package Lacuna::Role::Ship::Arrive::DumpWaste;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;
    
    # we're coming home
    return if ($self->direction eq 'in');
    
    # we're dumping on a star, nothing to do but go home
    return if $self->foreign_star_id;

    # dump it!
    my $body_attacked = $self->foreign_body;
    $body_attacked->add_waste($self->hold_size);
    $body_attacked->update;
    $self->body->empire->send_predefined_message(
        tags        => ['Attack','Alert'],
        filename    => 'our_scow_hit.txt',
        params      => [$body_attacked->x, $body_attacked->y, $body_attacked->name, $self->hold_size],
    );
    $body_attacked->empire->send_predefined_message(
        tags        => ['Attack','Alert'],
        filename    => 'hit_by_scow.txt',
        params      => [$self->body->empire_id, $self->body->empire->name, $body_attacked->id, $body_attacked->name, $self->hold_size],
    );
    $body_attacked->add_news(30, sprintf('%s is so polluted that waste seems to be falling from the sky.', $body_attacked->name));
    
    my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Battles');
    $logs->new({
        datestamp => DateTime->now,
        attacking_empire_id     => $self->body->empire_id,
        attacking_empire_name   => $self->body->empire->name,
        attacking_body_id       => $self->body_id,
        attacking_body_name     => $self->body->name,
        attacking_unit_name     => $self->name,
        defending_empire_id     => $body_attacked->empire_id,
        defending_empire_name   => $body_attacked->empire->name,
        defending_body_id       => $body_attacked->id,
        defending_body_name     => $body_attacked->name,
        defending_unit_name     => '',
        victory_to              => 'attacker',
    })->insert;

    # all pow
    $self->delete;
    confess [-1];
};

after send => sub {
    my $self = shift;
    $self->body->spend_waste($self->hold_size)->update;
    $self->payload({ resources => { waste => $self->hold_size } });
    $self->update;
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1013, 'Can only be sent to inhabited planets.'] if ($target->isa('Lacuna::DB::Result::Map::Body::Planet') && !$target->empire_id);
    confess [1011, 'You do not have enough waste to fill this scow. You need '.$self->hold_size.' waste to launch.'] unless ($self->body->waste_stored > $self->hold_size);
};

1;
