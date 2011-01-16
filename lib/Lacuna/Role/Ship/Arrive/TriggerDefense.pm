package Lacuna::Role::Ship::Arrive::TriggerDefense;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;
    
    # no defense at stars
    return unless $self->foreign_body_id;
    
    # no defense unless inhabited
    my $body_attacked = $self->foreign_body;
    return unless $body_attacked->empire_id;    
    
    # no defense against self
    return if $body_attacked->empire_id == $self->body->empire_id;
    
    # set last attack status
    $body_attacked->set_last_attacked_by($self->body->id);
        
    # get SAWs
    $self->saw_combat($body_attacked);
    my $alliance_id = $body_attacked->empire->alliance_id;
    if ($alliance_id) {
        my $bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({ empire_id => { '!=' => undef }, body_id => { '!=' => $body_attacked->id}, star_id => $body_attacked->star_id});
        while (my $body = $bodies->next) {
            if ($body->empire->alliance_id == $alliance_id) {
                $self->saw_combat($body);
            }
        }
    }

    # get defensive ships
    my $defense_ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        { body_id => $self->foreign_body_id, type => { in => [qw(fighter drone sweeper)]}, task=>'Docked'},
        );
    
    # if there are defensive ships let's duke it out
    while (my $defender = $defense_ships->next) {
        my $damage = $defender->combat;
        if ($defender->type eq 'drone') {
            $defender->delete;
        }
        else {
            $defender->combat( $defender->combat - $damage );
            if ($defender->combat < 1) {
                $defender->delete;
            }
            else {
                $defender->send(target => $body_attacked->star);
            }
        }
        $self->damage_in_combat($damage);
    }
};


sub damage_in_combat {
    my ($self, $damage) = @_;
    $self->combat( $self->combat - $damage );
    return unless $self->combat < 1;
    my $body_attacked = $self->foreign_body;
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
    confess [-1]
}

sub saw_combat {
    my ($self, $body) = @_;
    my $saws = $body->get_buildings_of_class('Lacuna::DB::Result::Building::SAW');
        
    # if there are SAWs lets duke it out
    while (my $saw = $saws->next) {
        next if $saw->level < 1;
        next if $saw->efficiency < 1;
        next if $saw->is_working;
        my $combat = ($saw->level * 1000) * ( $saw->efficiency / 100 );
        $saw->spend_efficiency( int( $self->combat / 100 ) );
        $saw->start_work({}, 60 * 5);
        $saw->update;
        $self->damage_in_combat($combat);
    }
}

1;
