package Lacuna::Role::Ship::Arrive::TriggerDefense;

use strict;
use Moose::Role;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint);

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # no defense at stars
    return unless $self->foreign_body_id;

    # only trigger defenses on arrival to the foreign body
    return if $self->direction eq 'in';

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

    # no defense against allies
    return if ( $is_planet && $body_attacked->empire && $body_attacked->empire->alliance_id && $ship_body->empire->alliance_id &&
               $body_attacked->empire->alliance_id == $ship_body->empire->alliance_id );

    # set last attack status
    $body_attacked->set_last_attacked_by($ship_body->id);

    # subtract from time being able to jump to neutral area
    $body_attacked->subtract_from_neutral_entry(int($self->combat/5));

    # Do Saw combat
    $self->system_saw_combat();

    # Do all fighters orbiting
    $self->allied_combat();

    # Do all ships that are defending from dock (drones, fighters, sweepers)
    $self->defender_combat();

};

sub citadel_interaction {
    my ($body_cit, $combat_def, $combat_att, $no_add) = @_;

    my ($citadel) = grep {
            $_->class eq 'Lacuna::DB::Result::Building::Permanent::CitadelOfKnope'
        and $_->efficiency > 0
        and $_->level > 0
    } @{$body_cit->building_cache};
    
    return $combat_def unless defined ($citadel);

    my $min_add = 900 / $citadel->effective_level;
    my $cooldown = 0;
    if ($citadel->is_working) {
        # Can we add more time?
        my $now = DateTime->now;
        $cooldown += $citadel->work_ends->epoch - $now->epoch;
        if ($cooldown + $min_add > 3600) {
            # we can't add any more time
            return $combat_def;
        }
    }
    my $max_add = 3600 - $cooldown;
    my $max_mult = 1 + ($max_add * $citadel->effective_efficiency * $citadel->effective_level)/3_600_000;
    # Mult will between 1 and 4
    return ($max_mult * $combat_def) if $no_add;
    
    my $threshold = $combat_att/10;
    my $add_secs = int($min_add * $threshold/$combat_def);
    $add_secs = $max_add if ($add_secs > $max_add);

    if ($citadel->is_working) {
        $citadel->reschedule_work($citadel->work_ends->add( seconds => $add_secs));
    }
    else {
        $citadel->start_work({}, $add_secs);
    }
    return ($max_mult * $combat_def);

}

sub damage_in_combat {
    my ($self, $damage) = @_;
    $self->combat( $self->combat - $damage );
    my $return;
    my $abid = $self->body_id;
    if ($self->type eq "attack_group") {
        my $payload = $self->payload;
        my %del_keys;
        for my $key (sort keys %{$payload->{fleet}}) {
            my ($sort_val, $type, $combat, $speed, $stealth, $hold_size) = split(/:/, $key);
            my $combat_part = $combat * $payload->{fleet}->{"$key"}->{quantity};
            if ($combat_part > $damage) {
                my $ships_destroyed = int($damage/$combat);
                $payload->{fleet}->{"$key"}->{quantity} -= $ships_destroyed;
                $self->number_of_docks($self->number_of_docks - $ships_destroyed);

                if ($return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}) {
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{number} += $ships_destroyed;
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{extra} = "a".$damage;
                }
                else {
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{body_id} = $abid;
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{body_name} = $self->body->name;
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{emp_id} = $self->body->empire_id;
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{emp_name} = $self->body->empire->name;
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{number} = $ships_destroyed;
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{extra} = "b".$damage;
                }
                $damage = 0;
            }
            else {
                if ($return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}) {
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{number} += $payload->{fleet}->{"$key"}->{quantity};
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{extra} = "c".$damage;
                }
                else {
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{body_id} = $abid;
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{body_name} = $self->body->name;
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{emp_id} = $self->body->empire_id;
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{emp_name} = $self->body->empire->name;
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{number} += $payload->{fleet}->{"$key"}->{quantity};
                    $return->{$abid}->{$payload->{fleet}->{"$key"}->{type}}->{extra} = "d".$damage;
                }
                $damage -= $combat_part;
                $del_keys{"$key"} = 1;
            }
            last if $damage == 0;
        }
        for my $key (keys %del_keys) {
            delete $payload->{fleet}->{"$key"};
        }
        if ($self->combat >= 0) {
#No need to reset payload if ship is being destroyed.
            $self->payload($payload);
        }
    }
    else {
        $return->{$abid}->{$self->type}->{body_id} = $abid;
        $return->{$abid}->{$self->type}->{body_name} = $self->body->name;
        $return->{$abid}->{$self->type}->{emp_id} = $self->body->empire_id;
        $return->{$abid}->{$self->type}->{emp_name} = $self->body->empire->name;
        $return->{$abid}->{$self->type}->{number} = 1;
        $return->{$abid}->{$self->type}->{extra} = $damage;
    }
    $self->update;
    return $return;
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

    my $attack_eid = $self->body->empire_id;
    my $attack_aid = 0;
    $attack_aid = $self->body->empire->alliance_id if ($self->body->alliance);
    my $attack_combat = $self->combat;

    my $defense_stat;
    # if there are ships let's duke it out
    while (my $ship = $ships->next) {
        # don't fight our own ships
        next if $attack_eid == $ship->body->empire_id;

        # don't fight our alliance
        if ( ($ship->body->empire->alliance && $attack_aid) && 
             ($ship->body->empire->alliance == $attack_aid)) {
            next;
        }

        # defender dealt this damage
        my $damage = $ship->combat;
        $damage = citadel_interaction($self->foreign_body, $damage, $attack_combat, 1);

        my $dbid = $ship->body_id;
        my $stype = $ship->type;
        if ($defense_stat->{$dbid}->{$stype}) {
            $defense_stat->{$dbid}->{$stype}->{number} += 1;
        }
        else {
            $defense_stat->{$dbid}->{$stype}->{body_id} = $dbid;
            $defense_stat->{$dbid}->{$stype}->{body_name} = $ship->body->name;
            $defense_stat->{$dbid}->{$stype}->{emp_id} = $ship->body->empire_id;
            $defense_stat->{$dbid}->{$stype}->{emp_name} = $ship->body->empire->name;
            $defense_stat->{$dbid}->{$stype}->{number} = 1;
        }
        if ($ship->type eq 'drone') {
            $ship->delete;
        }
        else {
            # subtract attacker's damage dealt from defender
            $ship->combat( $ship->combat - $attack_combat );
            if ($ship->combat < 1) {
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
        $attack_combat -= $damage;
        last if $attack_combat < 0;
    }
    my $attack_stat = $self->damage_in_combat($self->combat - $attack_combat);
    $self->notify_battle_results($defense_stat, $attack_stat);
    return unless $self->combat < 0;
    $self->delete;
    confess [-1]
}

sub allied_combat {
    my ($self) = @_;

    my $attacked_body = $self->foreign_body;
    my $ship_body = $self->body;
    my $is_planet = $attacked_body->isa('Lacuna::DB::Result::Map::Body::Planet');
    my $is_asteroid = $attacked_body->isa('Lacuna::DB::Result::Map::Body::Asteroid');
    my $is_station = 0;
    $is_station = 1 if ($attacked_body->get_type eq 'space station');

    my $defend_eid = 0;
    my $defend_aid = 0;
    my $attack_aid = 0;
    if ($attacked_body->empire) {
        $defend_eid = $attacked_body->empire_id;
        $defend_aid = $attacked_body->empire->alliance_id if ($attacked_body->empire->alliance_id);
    }

    my $attack_eid = $ship_body->empire_id;
    $attack_aid = $ship_body->empire->alliance_id if ($ship_body->alliance);

    if ($defend_aid != 0 and $attack_aid != 0) {
        return if ($defend_aid == $attack_aid);
    }

    if ($attacked_body->in_starter_zone and !$attacked_body->empire) {
        return;
    }

    my @allied_bodies;
    if ($attack_aid) {
        my @allied_empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search(
            {
                alliance_id => $attack_aid,
            });
        @allied_bodies = Lacuna->db->resultset('Lacuna::DB::Result::Body')->search(
            {
                empire_id => { 'in' => \@allied_empire, },
            });
    }
    my $ship_db = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    my $fighters_orbit = $ship_db->search(
                       {
                           foreign_body_id => $attacked_body->id,
			   type => 'fighter',
			   task => 'Defend',
                           body_id => { 'not in' => \@allied_bodies, },
                       });
    undef @allied_bodies;
    # initiate ship to ship combat between the attackers and the allied ships
    if ($fighters_orbit->count) {
        $self->ship_to_ship_combat($fighters_orbit);
    }
}

sub defender_combat {
    my ($self) = @_;

    # get defensive ships
    my $defense_ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {
          body_id => $self->foreign_body_id,
          type => { in => [ qw(fighter drone sweeper) ] },
          task=>'Docked',
        });

    # initiate ship to ship combat between the attackers and the defensive ships
    if ($defense_ships->count) {
        $self->ship_to_ship_combat($defense_ships);
    }
}

sub system_saw_combat {
    my ($self) = @_;

    my $attacked_body = $self->foreign_body;
    my $ship_body = $self->body;
    my $is_planet = $attacked_body->isa('Lacuna::DB::Result::Map::Body::Planet');
    my $is_asteroid = $attacked_body->isa('Lacuna::DB::Result::Map::Body::Asteroid');
    my $is_station = 0;
    $is_station = 1 if ($attacked_body->get_type eq 'space station');

    my $defend_eid = 0;
    my $defend_aid = 0;
    my $attack_aid = 0;
    if ($attacked_body->empire) {
        $defend_eid = $attacked_body->empire_id;
        $defend_aid = $attacked_body->empire->alliance_id if ($attacked_body->empire->alliance_id);
    }

    my $ship_eid = $ship_body->empire_id;
    my $ship_aid = $ship_body->empire->alliance_id;

    if ($defend_aid != 0 and $ship_aid != 0) {
        return if ($defend_aid == $ship_aid);
    }

    if ($attacked_body->in_starter_zone and !$attacked_body->empire) {
        return;
    }

    my $defending_bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')
                            ->search({
                                'me.star_id' => $attacked_body->star_id,
                                'empire.alliance_id' => { '!=' => $ship_aid },
                            },
                            {
                                join => 'empire',
                            });
# Here's where we get total number of defending SAWs
# 1) Get all Saws and total combat value
    my $total_combat = 0;
    my $saw_number   = 0;
    my @saws;
    my $def_cnt = 0;

    my $defense_stat;
    while (my $dbody = $defending_bodies->next) {
        next unless $dbody->isa('Lacuna::DB::Result::Map::Body::Planet');
        my ($saws, $combat) = saw_stats($dbody);
        next unless $combat > 0;
        my $dbid = $dbody->id;
        $def_cnt++;
        $combat *= 1.55 if ($dbid == $attacked_body->id);
        $combat *= 1.55 if ($dbody->empire_id == $attacked_body->empire_id);
        $combat *= 1.55 if (($dbody->empire->alliance and $defend_aid != 0) and
                            ($dbody->empire->alliance_id == $defend_aid));
        $combat = citadel_interaction($dbody, $combat, $self->combat, 0);
        push @saws, @$saws;
        $total_combat += $combat;
        $defense_stat->{$dbid}->{"Saws"}->{number} = scalar @$saws;
        $defense_stat->{$dbid}->{"Saws"}->{body_id} = $dbid;
        $defense_stat->{$dbid}->{"Saws"}->{body_name} = $dbody->name;
        $defense_stat->{$dbid}->{"Saws"}->{emp_id} = $dbody->empire_id;
        $defense_stat->{$dbid}->{"Saws"}->{emp_name} = $dbody->empire->name;
        $defense_stat->{$dbid}->{"Saws"}->{extra} = $combat;
    }
    $total_combat *= $def_cnt if $is_station;
    return if $total_combat < 1;
    my $num_saws = scalar @saws;
    my $percent = int($self->combat * 100/$total_combat);
    my $max_eff = $percent + 1;
    my $min_eff = int($max_eff/2);
    for my $saw (@saws) {
        my $effect = randint($min_eff,$max_eff);
        $saw->spend_efficiency($effect);
        unless ($saw->is_working) {
            $saw->start_work({}, 60 * 15);
        }
        $saw->update;
    }
    my $attack_stat = $self->damage_in_combat($total_combat);
    $self->notify_battle_results($defense_stat, $attack_stat);
    return unless $self->combat < 1;
    $self->delete;
    confess [-1]
}

sub notify_battle_results {
    my ($self, $defense_stat, $attack_stat) = @_;

    my $report;
    for my $dbid (keys %{$defense_stat}) {
        for my $dtype (keys %{$defense_stat->{$dbid}}) {
            push @{$report}, [
                $dbid,
                $defense_stat->{$dbid}->{$dtype}->{body_name},
                $defense_stat->{$dbid}->{$dtype}->{emp_id},
                $defense_stat->{$dbid}->{$dtype}->{emp_name},
                $dtype,
                $defense_stat->{$dbid}->{$dtype}->{number},
                $defense_stat->{$dbid}->{$dtype}->{extra},
            ];
        }
    }
    unshift @{$report}, (['Defenders','','','','',''],['ID','Planet','EID','Empire','Type','Number','Extra']);
    push @{$report}, (['Attackers','','','','',''],['ID','Planet','EID','Empire','Type','Number','Extra']);
    for my $abid (keys %{$attack_stat}) {
        for my $atype (keys %{$attack_stat->{$abid}}) {
            push @{$report}, [
                $abid,
                $attack_stat->{$abid}->{$atype}->{body_name},
                $attack_stat->{$abid}->{$atype}->{emp_id},
                $attack_stat->{$abid}->{$atype}->{emp_name},
                $atype,
                $attack_stat->{$abid}->{$atype}->{number},
                $attack_stat->{$abid}->{$atype}->{extra},
            ];
        }
    }

    $self->body->empire->send_predefined_message(
            tags        => ['Attack'],
            filename    => 'attack_summary.txt',
            params      => [$self->foreign_body->id,
                            $self->foreign_body->name,
                           ],
            attachments => { table => $report },
        );

    if ($self->foreign_body->empire) {
        $self->foreign_body->add_news(20,
                     sprintf('A space battle occured over %s today.',
                     $self->foreign_body->name));
    }
    else {
        $self->body->add_news(20,
                     sprintf('Action reported by a %s squadron out of %s today.',
                     $self->body->empire->name, $self->body->name));
    }
}

sub saw_stats {
    my ($body) = @_;

    my @planet_saws = Lacuna->db->resultset('Building')->search({
        body_id     => $body->id,
        class       => 'Lacuna::DB::Result::Building::SAW',
        efficiency  => { '>' => 0 },
        level       => { '>' => 0 },
    });

    my $planet_combat = 0;
    my $cnt = 0;
    my @defending_saws;
    for my $saw (@planet_saws) {
        $cnt++;
        $planet_combat += 60 * (($saw->effective_level + 1) * ($saw->effective_level + 1) * $saw->effective_efficiency);
        push @defending_saws, $saw;
        last if $cnt >= 10;
    }
    return \@defending_saws, $planet_combat;
}

1;
