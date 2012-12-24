package Lacuna::Role::Fleet::Arrive::TriggerDefense;

use strict;
use Moose::Role;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint);

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # no defense at stars
    return unless $self->foreign_body_id;

    # No defense in Neutral Area.  (Can't stop colonization, mining, etc...)
    return if $self->foreign_body->in_neutral_area;

    my $body_attacked   = $self->foreign_body;
    my $from_body       = $self->body;
    my $is_planet       = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Planet');
    my $is_asteroid     = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Asteroid');
    return unless ( $is_planet || $is_asteroid );

    # no defense against self
    return if ( $is_planet && $body_attacked->empire && $body_attacked->empire_id == $from_body->empire_id );

    # only trigger defenses on arrival at the foreign body
    return if $self->direction eq 'in';

    # set last attack status
    $body_attacked->set_last_attacked_by($from_body->id);

    # get SAWs
    $self->system_saw_combat;

    # get allies
    $self->allied_combat();

    $self->defender_combat();
};

# $self is the attacking fleet
# $defender is either a defending ship, or a SAW
#
sub damage_in_combat {
    my ($self, $defender, $damage) = @_;

    if (not $self->survives_damage($damage)) {
        $self->attacker_shot_down($defender);
        confess [-1];
    }
    return $self;
}


# $self is the attacking fleet
# $defender is the defending ship or SAW
#
sub attacker_shot_down {
    my ($self, $defender) = @_;

    my $body_attacked = $self->foreign_body;

    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'ship_shot_down.txt',
            params      => [
                $self->type_formatted,
                $body_attacked->x,
                $body_attacked->y,
                $body_attacked->name,
                $self->body->id,
                $self->body->name,
            ],
        );
    }

    unless ($defender->body->empire_id && $defender->body->empire->skip_attack_messages) {
        $defender->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'we_shot_down_a_ship.txt',
            params      => [
                $self->type_formatted,
                $body_attacked->id,
                $body_attacked->name,
                $self->body->empire_id,
                $self->body->empire->name,
            ],
        );
    }

    $defender->body->add_news(20,
        sprintf('An amateur astronomer witnessed an explosion in the sky today over %s.',
            $body_attacked->name)
    );

    log_attack( $self, $defender, 'defender' );
}

sub saw_disabled {
    my ($self, $defender) = @_;
    my $body_attacked = $self->foreign_body;

    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'saw_neutralized.txt',
            params      => [
                $defender->body->x,
                $defender->body->y,
                $defender->body->name,
                $defender->body->empire_id,
                $defender->body->empire->name,
                $body_attacked->x,
                $body_attacked->y,
                $body_attacked->name,
            ],
        );
    }


    unless ($defender->body->empire_id && $defender->body->empire->skip_attack_messages) {
        $defender->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'saw_disabled.txt',
            params      => [
                $defender->body->x,
                $defender->body->y,
                $defender->body->name,
                $body_attacked->x,
                $body_attacked->y,
                $body_attacked->name,
                $self->body->empire_id,
                $self->body->empire->name,
                $self->type_formatted,
            ],
        );
    }
    log_attack($self, $defender, 'attacker');
}

# $self is the attacking fleet
# $defender is the defending fleet
#
sub report_defender_shot_down {
    my ($self, $defender) = @_;
    my $body_attacked = $self->foreign_body;

    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'we_shot_down_a_defender.txt',
            params      => [
                $defender->type_formatted,
                $body_attacked->x,
                $body_attacked->y,
                $body_attacked->name,
                $defender->body->empire_id,
                $defender->body->empire->name,
            ],
        );
    }

    unless ($defender->body->empire_id && $defender->body->empire->skip_attack_messages) {
        $defender->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'defender_shot_down.txt',
            params      => [
                $defender->type_formatted,
                $defender->body->id,
                $defender->body->name,
                $body_attacked->x,
                $body_attacked->y,
                $body_attacked->name,
            ],
        );
    }

    $defender->body->add_news(20,
        sprintf('An amateur astronomer witnessed an explosion in the sky today over %s.',
            $body_attacked->name));

    log_attack( $self, $defender, 'attacker' );
}


sub log_attack {
    my ($attacker, $defender, $victor) = @_;
    my $body_attacked = $attacker->foreign_body;
    my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Battles');
    $logs->new({
        date_stamp => DateTime->now,
        attacking_empire_id     => $attacker->body->empire_id,
        attacking_empire_name   => $attacker->body->empire->name,
        attacking_body_id       => $attacker->body_id,
        attacking_body_name     => $attacker->body->name,
        attacking_unit_name     =>
            $attacker->isa('Lacuna::DB::Result::Building') ?
            sprintf("%s (%d,%d)", $attacker->name, $attacker->x, $attacker->y) :
            $attacker->name,
        attacking_type          => 
            $attacker->isa('Lacuna::DB::Result::Building') ?
            $attacker->name : $attacker->type_formatted,
        defending_empire_id     => $defender->body->empire_id,
        defending_empire_name   => $defender->body->empire->name,
        defending_body_id       => $defender->body->id,
        defending_body_name     => $defender->body->name,
        defending_unit_name     => $defender->isa('Lacuna::DB::Result::Building') ?
            sprintf("%s (%d,%d)", $defender->name, $defender->x, $defender->y) :
            $defender->name,
        defending_type          => 
            $defender->isa('Lacuna::DB::Result::Building') ?
            $defender->name : $defender->type_formatted,
        attacked_empire_id     => defined($body_attacked->empire) ? $body_attacked->empire_id : 0,
        attacked_empire_name   => defined($body_attacked->empire) ? $body_attacked->empire->name : "",
        attacked_body_id       => $body_attacked->id,
        attacked_body_name     => $body_attacked->name,
    })->insert;
}

# $self is the attacking fleet
# $fleets are the defending (own or allies)
#
sub fleet_to_fleet_combat {
    my ($self, $defending_fleets) = @_;

    my %body_empire;
    my $attacking_empire_id     = $self->body->empire_id;
    my $attacking_alliance_id   = $self->body->empire->alliance_id;

    # if there are ships let's duke it out
    while (my $defending_fleet = $defending_fleets->next) {
        # don't fight our own fleets
        my $defending_empire_id = $body_empire{$defending_fleet->body_id} //= $defending_fleet->body->empire_id;
        if ($attacking_empire_id == $defending_empire_id) {
            next;
        }

        # don't fight our alliance
        my $defending_alliance_id = $defending_fleet->body->empire->alliance_id;
        if ( $attacking_alliance_id && $defending_alliance_id && $attacking_alliance_id == $defending_alliance_id ) {
            next;
        }

        # defender dealt this damage
        my $defending_combat = $defending_fleet->combat * $defending_fleet->quantity;

        # TODO Don't destroy the whole drone fleet
        if ($defending_fleet->type eq 'drone') {
            $defending_fleet->delete;
        }

        else {
            # subtract attacker's damage dealt from defender
            $defending_fleet->combat( $defending_fleet->combat - $self->combat );
            if ($defending_fleet->combat < 1) {
                $self->defender_shot_down($defending_fleet);
                $defending_fleet->delete;
            }
            else {
                # just return home
                if ($defending_fleet->task eq 'Defend') {
                    $defending_fleet->send(
                        target      => $self->foreign_body,
                        direction   => 'in',
                    );
                }
                else {
                    # reset to star and back
                    $defending_fleet->send(target => $self->foreign_body->star);
                }
            }
        }

        $self->damage_in_combat($defending_fleet, $defending_combat);
    }
}


sub defender_combat {
    my ($self) = @_;

    # get defensive fleets
    my $defense_fleets = Lacuna->db->resultset('Fleet')->search({
        body_id     => $self->foreign_body_id, 
        type        => { in => [ qw(fighter drone sweeper) ] },
        task        => 'Docked',
    });

    # initiate fleet to fleet combat between the attackers and the defenders
    $self->fleet_to_fleet_combat($defense_fleets);
}


sub allied_combat {
    my ($self) = @_;

    # get allied defenders
    my $allied_fleets = Lacuna->db->resultset('Fleet')->search({
        foreign_body_id => $self->foreign_body_id,
        type            => 'fighter',
        task            => 'Defend',
    });
    # initiate fleet to fleet combat between the attackers and the defenders
    $self->fleet_to_fleet_combat($allied_fleets);
}

sub system_saw_combat {
    my ($self) = @_;

    my $attacked_body = $self->foreign_body;
    my $from_body = $self->body;

    my $attacked_empire = $attacked_body->empire_id;
    my $attacked_alliance = $attacked_body->alliance_id
      || ($attacked_body->empire && $attacked_body->empire->alliance_id);

    my $ship_empire = $from_body->empire_id;
    my $ship_alliance = $from_body->empire->alliance_id;

    # All other defending bodies around this star
    my $defending_bodies = Lacuna->db->resultset('Map::Body')->search({
        id      => { '!=' => $attacked_body->id}, 
        star_id => $attacked_body->star_id,
    });

    # Here's where we get total number of defending SAWs
    # 1) Get Targetted Planet's SAWs first.
    # 2) Go thru and get all SAWs hostile to incoming.
    my @other_saws;
    my $total_saw_combat    = 0;
    my $saw_number          = 0;
    my $defending_saws      = [];
    my $defending_combat    = 0;
    if ($attacked_body->isa('Lacuna::DB::Result::Map::Body::Planet')) {
        ( $defending_saws, $defending_combat ) = $self->saw_stats($attacked_body);
    }

    # Attacked planet defense a bit more fierce.
    $total_saw_combat += 2 * $defending_combat;
    while (my $defending_body = $defending_bodies->next) {
        # asteroids don't have SAWs
        next unless $defending_body->isa('Lacuna::DB::Result::Map::Body::Planet');

        my $defending_empire = $defending_body->empire_id;
        my $defending_alliance = $defending_body->alliance_id
            || ($defending_body->empire && $defending_body->empire->alliance_id);

        if ( $defending_empire && $defending_empire == $ship_empire ) {
            # don't attack ships from same empire
        }
        elsif ( $defending_empire && $attacked_empire && $defending_empire == $attacked_empire ) {
            # defend own planets in system
            my ( $saws, $other_combat ) = $self->saw_stats($defending_body);
            push @other_saws, @$saws;
            $total_saw_combat += $other_combat;
        }
        elsif ( $defending_alliance && $ship_alliance && $defending_alliance == $ship_alliance ) {
            # don't attack ships in same alliance
        }
        else {
            # attack everything else
            my ( $saws, $combat ) = $self->saw_stats($defending_body);
            push @other_saws, @$saws;
            $total_saw_combat += $combat;
        }
    }

    # Defending Planet SAWs go first, then random from other planets.
    for my $saw ((shuffle @$defending_saws), shuffle @other_saws) {
        $self->saw_combat($saw, $total_saw_combat);
    }
}

# Get stats for defending saws
#
sub saw_stats {
    my ($self, $body) = @_;

    my @planet_saws = $body->get_buildings_of_class('Lacuna::DB::Result::Building::SAW');

    # unweaken body
    map {$_->body($_->body)} @planet_saws;

    my $planet_combat   = 0;
    my $max_saws        = 0;
    my @defending_saws;
    SAW:
    for my $saw (@planet_saws) {
        $max_saws++;
        next if $saw->level < 1;
        next if $saw->efficiency < 1;
        $planet_combat += int( (5 * ($saw->level + 1) * ($saw->level+1) * $saw->efficiency)/2 + 0.5);
        push @defending_saws, $saw;
        last SAW if $max_saws >= 10;
    }
    return \@defending_saws, $planet_combat;
}

# Combat this fleet against a single SAW
# 
sub saw_combat {
    my ($self, $saw, $total_saw_combat) = @_;

    return if ($saw->efficiency == 0);
  
    if ($self->combat >= $total_saw_combat) {
        $saw->spend_efficiency(100);
        $self->saw_disabled($saw);
    }
    else {
        my $perc_1 = int( ($self->combat * 100)/$total_saw_combat + 0.5);
        my $perc_2 = int( $self->combat * 100/
                       (5 * ($saw->level + 1) * ($saw->level+1) * $saw->efficiency));
        $perc_2 = 100 if $perc_2 > 99;
        if ($perc_1 < 1) {
            $perc_2 = $perc_2 > 1               ? $perc_2   : 1;
            $perc_1 = (randint(0,99) < $perc_2) ? 1         : 0;
        }
        $perc_1 = $perc_1 == 1 ? 1 : int($perc_1 * $saw->efficiency/100 +0.5);
        $saw->spend_efficiency($perc_1);
    }
    unless ($saw->is_working) {
        $saw->start_work({}, 60 * 15);
    }
    $saw->update;
    $self->damage_in_combat($saw, $total_saw_combat);
}

1;

