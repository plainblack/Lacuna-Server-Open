package Lacuna::Role::Ship::Arrive::TriggerDefense;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;
    
    # no defense at stars
    return $self->foreign_body_id;
    
    # no defense unless inhabited
    my $body_attacked = $self->foreign_body;
    return unless $body_attacked->empire_id;    
    
    # no defense against self
    return if $body_attacked->empire_id == $self->body->empire_id;
        
    # get defensive ships
    my $defense = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        { body_id => $self->foreign_body_id, type => { in => [qw(drone fighter)]}, task=>'Docked'},
        { rows => 1 }
        )->single;
    
    # if there are defensive ships let's duke it out
    if (defined $defense) {
        $self->body->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'ship_shot_down.txt',
            params      => [$self->type_formatted, $body_attacked->x, $body_attacked->y, $body_attacked->name, $self->body->id, $self->body->name],
        );
        $body_attacked->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'we_shot_down_a_ship.txt',
            params      => [$self->type_formatted, $body_attacked->id, $body_attacked->name, $self->body->empire_id, $self->body->empire->name],
        );
        $body_attacked->add_news(20, sprintf('An amateur astronomer witnessed an explosion in the sky today over %s.',$body_attacked->name));
        $self->delete;
        if ($defense->type eq 'fighter' && randint(1,100) > 50) {
            # fighter lives
        }
        else {
            $defense->delete;
        }
        confess [-1]
    }
};

1;
