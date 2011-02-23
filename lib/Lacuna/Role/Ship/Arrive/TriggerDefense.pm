package Lacuna::Role::Ship::Arrive::TriggerDefense;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # no defense at stars
    return unless $self->foreign_body_id;
 
    my $body_attacked = $self->foreign_body;
	my $is_planet = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Planet');
	my $is_asteroid = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Asteroid');
    return unless ( $is_planet || $is_asteroid );
 
    # no defense against self
    return if ( $is_planet && $body_attacked->empire && $body_attacked->empire_id == $self->body->empire_id );

	# only trigger defenses on arrival to the foreign body
	return if $self->direction eq 'in';
 
    # set last attack status
    $body_attacked->set_last_attacked_by($self->body->id);

	# get allies
	$self->allied_combat();
 
    # get SAWs
    $self->saw_combat($body_attacked) if $is_planet;

    my $alliance_id;
	if ( $is_planet && $body_attacked->empire ) { 
		$alliance_id = $body_attacked->empire->alliance_id;
	}
	my $bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({ id => { '!=' => $body_attacked->id}, star_id => $body_attacked->star_id});
	while (my $body = $bodies->next) {
		next unless ( $body->empire_id || $is_asteroid );
		if ( $is_asteroid || $body->empire->alliance_id == $alliance_id ) {
			$self->saw_combat($body) if $body->isa('Lacuna::DB::Result::Map::Body::Planet');
		}
	}

	$self->defender_combat();
};

sub damage_in_combat {
    my ($self, $defender, $damage) = @_;
    $self->combat( $self->combat - $damage );
    return unless $self->combat < 1;
    my $body_attacked = $self->foreign_body;
    $self->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_shot_down.txt',
        params      => [$self->type_formatted, $body_attacked->x, $body_attacked->y, $body_attacked->name, $self->body->id, $self->body->name],
    );
    $defender->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'we_shot_down_a_ship.txt',
        params      => [$self->type_formatted, $body_attacked->id, $body_attacked->name, $defender->body->empire_id, $defender->body->empire->name],
    );
    $defender->body->add_news(20, sprintf('An amateur astronomer witnessed an explosion in the sky today over %s.',$body_attacked->name));
    $self->delete;
    confess [-1]
}

sub ship_to_ship_combat {
	my ($self, $ships) = @_;

    # if there are ships let's duke it out
    while (my $ship = $ships->next) {
        my $damage = $ship->combat;
        if ($ship->type eq 'drone') {
            $ship->delete;
			next;
        }
		$ship->combat( $ship->combat - $self->combat );
		if ($ship->combat < 1) {
			$ship->delete;
		}
		else {
			$ship->send(target => $self->foreign_body->star);
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

    # get allied ships
    my $allied_ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        { foreign_body_id => $self->foreign_body_id, type => { in => [qw(fighter)]}, task => 'Defend' },
	);

	# initiate ship to ship combat between the attackers and the allied ships
	$self->ship_to_ship_combat($allied_ships);
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
