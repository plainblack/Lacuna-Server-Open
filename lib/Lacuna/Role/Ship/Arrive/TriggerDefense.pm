package Lacuna::Role::Ship::Arrive::TriggerDefense;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # no defense at stars
    return unless $self->foreign_body_id;

    my $body_attacked = $self->foreign_body;
    my $ship_body = $self->body;
    my $is_planet = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Planet');
    my $is_asteroid = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Asteroid');
    return unless ( $is_planet || $is_asteroid );

    # no defense against self
    return if ( $is_planet && $body_attacked->empire && $body_attacked->empire_id == $ship_body->empire_id );

    # only trigger defenses on arrival to the foreign body
    return if $self->direction eq 'in';

    # set last attack status
    $body_attacked->set_last_attacked_by($ship_body->id);

    # get SAWs
    $self->saw_combat($body_attacked) if $is_planet;

    $self->system_saw_combat;

    # get allies
    $self->allied_combat();

    $self->defender_combat();
};

sub damage_in_combat {
    my ($self, $defender, $damage) = @_;
    $self->combat( $self->combat - $damage );
    return unless $self->combat < 1;
	$self->attacker_shot_down($defender);
    $self->delete;
    confess [-1]
}

sub attacker_shot_down {
	my ($self, $defender) = @_;
    my $body_attacked = $self->foreign_body;

    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'ship_shot_down.txt',
            params      => [$self->type_formatted, $body_attacked->x, $body_attacked->y, $body_attacked->name, $self->body->id, $self->body->name],
        );
    }

    unless ($defender->body->empire_id && $defender->body->empire->skip_attack_messages) {
        $defender->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'we_shot_down_a_ship.txt',
            params      => [$self->type_formatted, $body_attacked->id, $body_attacked->name, $self->body->empire_id, $self->body->empire->name],
        );
    }

    $defender->body->add_news(20, sprintf('An amateur astronomer witnessed an explosion in the sky today over %s.',$body_attacked->name));

    my $is_asteroid = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Asteroid');

    $self->log_attack( $self, $defender, 'defender' );
}

sub defender_shot_down {
	my ($self, $defender) = @_;
    my $body_attacked = $self->foreign_body;

    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'we_shot_down_a_defender.txt',
            params      => [$defender->type_formatted, $body_attacked->x, $body_attacked->y, $body_attacked->name, $defender->body->empire_id, $defender->body->empire->name],
        );
    }

    unless ($defender->body->empire_id && $defender->body->empire->skip_attack_messages) {
        $defender->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'defender_shot_down.txt',
            params      => [$defender->type_formatted, $defender->body->id, $defender->body->name, $body_attacked->x, $body_attacked->y, $body_attacked->name],
        );
    }

    $defender->body->add_news(20, sprintf('An amateur astronomer witnessed an explosion in the sky today over %s.',$body_attacked->name));

    my $is_asteroid = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Asteroid');

    $self->log_attack( $self, $defender, 'attacker' );
}

sub log_attack {
    my ($self, $attacker, $defender, $victor) = @_;
    my $body_attacked = $attacker->foreign_body;
    my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Battles');
    $logs->new({
        date_stamp => DateTime->now,
        attacking_empire_id     => $attacker->body->empire_id,
        attacking_empire_name   => $attacker->body->empire->name,
        attacking_body_id       => $attacker->body_id,
        attacking_body_name     => $attacker->body->name,
        attacking_unit_name     => $attacker->isa('Lacuna::DB::Result::Building') ? sprintf("%s (%d,%d)", $attacker->name, $attacker->x, $attacker->y) : $attacker->name,
        defending_empire_id     => $defender->body->empire_id,
        defending_empire_name   => $defender->body->empire->name,
        defending_body_id       => $body_attacked->id,
        defending_body_name     => $body_attacked->name,
        defending_unit_name     => $defender->isa('Lacuna::DB::Result::Building') ? sprintf("%s (%d,%d)", $defender->name, $defender->x, $defender->y) : $defender->name,
        victory_to              => $victor,
    })->insert;
}

sub ship_to_ship_combat {
    my ($self, $ships) = @_;

    my %body_empire;
    my $empire = $self->body->empire_id;

    # if there are ships let's duke it out
    while (my $ship = $ships->next) {
        # don't fight our own ships
        my $ship_empire = $body_empire{$ship->body_id} //= $ship->body->empire_id;
        if ($empire == $ship_empire) {
            next;
        }

        # defender dealt this damage
        my $damage = $ship->combat;
        if ($ship->type eq 'drone') {
            $ship->delete;
        }

        else {
            # subtract attacker's damage dealt from defender
            $ship->combat( $ship->combat - $self->combat );
            if ($ship->combat < 1) {
                $self->defender_shot_down($ship);
                $ship->delete;
            }
            else {
                # just return home
                if ($ship->task eq 'Defend') {
                    $ship->send(
                        target      => $self->foreign_body,
                        direction   => 'in',
                    );
                }
                else {
                    # reset to star and back
                    $ship->send(target => $self->foreign_body->star);
                }
            }
        }

        $self->damage_in_combat($ship, $damage);
    }
}

sub defender_combat {
	my ($self) = @_;

    # get defensive ships
    my $defense_ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        { body_id => $self->foreign_body_id, type => { in => [ qw(fighter drone sweeper) ] }, task=>'Docked' },
	);

	# initiate ship to ship combat between the attackers and the defensive ships
	$self->ship_to_ship_combat($defense_ships);
}

sub allied_combat {
	my ($self) = @_;
    my $body_attacked = $self->foreign_body;
	my $is_planet = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Planet');
	my $is_asteroid = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Asteroid');

    # get allied defenders
    my $allied_ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
		{
			foreign_body_id => $self->foreign_body_id,
			type => 'fighter',
			task => 'Defend',
		},
	);

	# initiate ship to ship combat between the attackers and the allied ships
	$self->ship_to_ship_combat($allied_ships);
}

sub system_saw_combat {
    my ($self) = @_;

    my $attacked_body = $self->foreign_body;
    my $ship_body = $self->body;
    my $is_planet = $attacked_body->isa('Lacuna::DB::Result::Map::Body::Planet');
    my $is_asteroid = $attacked_body->isa('Lacuna::DB::Result::Map::Body::Asteroid');

    my $attacked_empire = $attacked_body->empire_id;
    my $attacked_alliance = $attacked_body->alliance_id
        || ($attacked_body->empire && $attacked_body->empire->alliance_id);

    my $ship_empire = $ship_body->empire_id;
    my $ship_alliance = $ship_body->empire->alliance_id;

    my $defending_bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
        { id => { '!=' => $attacked_body->id}, star_id => $attacked_body->star_id }
    );
    while (my $defending_body = $defending_bodies->next) {
        # asteroids don't have SAWs
        next
            unless $defending_body->isa('Lacuna::DB::Result::Map::Body::Planet');

        my $defending_empire = $defending_body->empire_id;
        my $defending_alliance = $defending_body->alliance_id
            || ($defending_body->empire && $defending_body->empire->alliance_id);

        if ( $defending_empire && $defending_empire == $ship_empire ) {
            # don't attack ships from same empire
        }
        elsif ( $defending_empire && $attacked_empire && $defending_empire == $attacked_empire ) {
            # defend own planets in system
            $self->saw_combat($defending_body);
        }
        elsif ( $defending_alliance && $ship_alliance && $defending_alliance == $ship_alliance ) {
            # don't attack ships in same alliance
        }
        else {
            # attack everything else
            $self->saw_combat($defending_body);
        }
    }
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
        $self->damage_in_combat($saw, $combat);
    }
}

1;
