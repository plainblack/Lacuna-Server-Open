package Lacuna::Role::Ship::Arrive::TriggerDefense;

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

    my $body_attacked = $self->foreign_body;
    my $ship_body = Lacuna->db->resultset('Map::Body::Planet')->find({id => $self->body_id});
    $self->body($ship_body);

    my $is_planet = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Planet');
    my $is_asteroid = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Asteroid');
    return unless ( $is_planet || $is_asteroid );

    # no defense against self
    return if ( $is_planet && $body_attacked->empire && $body_attacked->empire_id == $ship_body->empire_id );

    # only trigger defenses on arrival to the foreign body
    return if $self->direction eq 'in';

    # set last attack status
    $body_attacked->set_last_attacked_by($ship_body->id);

    # subtract from time being able to jump to neutral area
    $body_attacked->subtract_from_neutral_entry(int($self->combat/5));

    # get SAWs
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
            params      => [$self->type_formatted,
                            $body_attacked->x,
                            $body_attacked->y,
                            $body_attacked->name,
                            $self->body->id,
                            $self->body->name],
        );
    }

    unless ($defender->body->empire_id && $defender->body->empire->skip_attack_messages) {
        $defender->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'we_shot_down_a_ship.txt',
            params      => [$self->type_formatted,
                            $body_attacked->id,
                            $body_attacked->name,
                            $self->body->empire_id,
                            $self->body->empire->name],
        );
    }

    $defender->body->add_news(20,
                 sprintf('An amateur astronomer witnessed an explosion in the sky today over %s.',
                 $body_attacked->name));

    my $is_asteroid = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Asteroid');

    log_attack( $self, $defender, 'defender' );
#    $self->log_attack( $defender, 'defender' );
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
                       $body_attacked->name],
      );
  }

  unless ($defender->body->empire_id && $defender->body->empire->skip_attack_messages) {
    $defender->body->empire->send_predefined_message(
       tags        => ['Attack','Alert'],
       filename    => 'saw_disabled.txt',
       params      => [$defender->body->x,
                       $defender->body->y,
                       $defender->body->name,
                       $body_attacked->x,
                       $body_attacked->y,
                       $body_attacked->name,
                       $self->body->empire_id,
                       $self->body->empire->name,
                       $self->type_formatted],
    );
  }
  log_attack($self, $defender, 'attacker');
}

sub defender_shot_down {
	my ($self, $defender) = @_;
    my $body_attacked = $self->foreign_body;

    unless ($self->body->empire->skip_attack_messages) {
        $self->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'we_shot_down_a_defender.txt',
            params      => [$defender->type_formatted,
                            $body_attacked->x,
                            $body_attacked->y,
                            $body_attacked->name,
                            $defender->body->empire_id,
                            $defender->body->empire->name],
        );
    }

    unless ($defender->body->empire_id && $defender->body->empire->skip_attack_messages) {
        $defender->body->empire->send_predefined_message(
            tags        => ['Attack','Alert'],
            filename    => 'defender_shot_down.txt',
            params      => [$defender->type_formatted,
                            $defender->body->id,
                            $defender->body->name,
                            $body_attacked->x,
                            $body_attacked->y,
                            $body_attacked->name],
        );
    }

    $defender->body->add_news(20,
                     sprintf('An amateur astronomer witnessed an explosion in the sky today over %s.',
                     $body_attacked->name));

    my $is_asteroid = $body_attacked->isa('Lacuna::DB::Result::Map::Body::Asteroid');

    log_attack( $self, $defender, 'attacker' );
#    $self->log_attack( $defender, 'attacker' );
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
     victory_to              => $victor,
     attacked_empire_id     => defined($body_attacked->empire) ? $body_attacked->empire_id : 0,
     attacked_empire_name   => defined($body_attacked->empire) ? $body_attacked->empire->name : "",
     attacked_body_id       => $body_attacked->id,
     attacked_body_name     => $body_attacked->name,
  })->insert;
}

sub ship_to_ship_combat {
    my ($self, $ships) = @_;

    my %body_empire;
    my $empire = $self->body->empire_id;
    my $alliance = $self->body->empire->alliance_id;

    # if there are ships let's duke it out
    while (my $ship = $ships->next) {
        # don't fight our own ships
        my $ship_empire = $body_empire{$ship->body_id} //= $ship->body->empire_id;
        if ($empire == $ship_empire) {
            next;
        }

        # don't fight our alliance
        my $ship_alliance = $ship->body->empire->alliance_id;
        if ( $alliance && $ship_alliance && $alliance == $ship_alliance ) {
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

  if ($attacked_alliance && $ship_alliance) {
      return if ($attacked_alliance == $ship_alliance);
  }

  if ($attacked_body->in_starter_zone and !$attacked_body->empire) {
      return;
  }

  my $defending_bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
      { id => { '!=' => $attacked_body->id}, star_id => $attacked_body->star_id }
  );
# Here's where we get total number of defending SAWs
# 1) Get Targetted Planet's SAWs first.
# 2) Go thru and get all SAWs hostile to incoming.
  my $total_combat = 0;
  my $saw_number   = 0;
  my @saws;
  my $attacked_saws = [];
  my $attacked_combat = 0;
  ( $attacked_saws, $attacked_combat ) = $self->saw_stats($attacked_body)
     if ($attacked_body->isa('Lacuna::DB::Result::Map::Body::Planet'));
# Attacked planet defense a bit more fierce.
  $total_combat += 2 * $attacked_combat;
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
      my ( $saws, $combat ) = $self->saw_stats($defending_body);
      push @saws, @$saws;
      $total_combat += $combat;
    }
    elsif ( $defending_alliance && $ship_alliance && $defending_alliance == $ship_alliance ) {
      # don't attack ships in same alliance
    }
    else {
      # attack everything else
      my ( $saws, $combat ) = $self->saw_stats($defending_body);
      push @saws, @$saws;
      $total_combat += $combat;
    }
  }
# Defending Planet SAWs go first, then random from other planets.
  for my $saw ((shuffle @$attacked_saws), shuffle @saws) {
    $self->saw_combat($saw, $total_combat);
  }
}

sub saw_stats {
    my ($self, $body) = @_;

    my @planet_saws = Lacuna->db->resultset('Building')->search({
        body_id     => $body->id,
        class       => 'Lacuna::DB::Result::Building::SAW',
    });

    my $planet_combat = 0;
    my $cnt = 0;
    my @defending_saws;
    for my $saw (@planet_saws) {
        $cnt++;
        next if $saw->effective_level < 1;
        next if $saw->effective_efficiency < 1;
        $planet_combat += int( (5 * ($saw->effective_level + 1) * ($saw->effective_level+1) * $saw->effective_efficiency)/2 + 0.5);
        push @defending_saws, $saw;
        last if $cnt >= 10;
    }
    return \@defending_saws, $planet_combat;
}

sub saw_combat {
  my ($self, $saw, $total_combat) = @_;

  return if ($saw->efficiency == 0);
#  printf "ship:%6d:%5d saw:%6d:%2d:%3d total:%8d ",
#         $self->id, $self->combat, $saw->id, $saw->effective_level, $saw->effective_efficiency, $total_combat;
  if ($self->combat >= $total_combat) {
    $saw->spend_efficiency(100);
    $self->saw_disabled($saw);
#    print "100\n";
  }
  else {
    my $perc_1 = int( ($self->combat * 100)/$total_combat + 0.5);
    my $perc_2 = int( $self->combat * 100/
                       (5 * ($saw->effective_level + 1) * ($saw->effective_level+1) * $saw->effective_efficiency));
    $perc_2 = 100 if $perc_2 > 99;
    if ($perc_1 < 1) {
      $perc_2 = $perc_2 > 1 ? $perc_2 : 1;
      if (randint(0,99) < $perc_2) { $perc_1 = 1; } else { $perc_1 = 0; }
    }
    $perc_1 = $perc_1 == 1 ? 1 : int($perc_1 * $saw->efficiency/100 +0.5);
#    printf "%3d\n", $perc;
    $saw->spend_efficiency($perc_1);
  }
  unless ($saw->is_working) {
    $saw->start_work({}, 60 * 15);
  }
  $saw->update;
  $self->damage_in_combat($saw, $total_combat);
}

1;
