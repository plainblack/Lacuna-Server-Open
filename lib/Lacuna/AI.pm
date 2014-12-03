package Lacuna::AI;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Lacuna::Util qw(randint random_element);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use List::Util qw(shuffle);
use 5.010;
use Module::Find;

has empire      => (
   is           => 'ro',
   lazy         => 1,
   default      => sub {
        my $self = shift;
        my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($self->empire_id);
        if (defined $empire) {
            return $empire;
        }
        else {
            return $self->create_empire;
        }
   }
);

has scratch     => (
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        my ($scratch) = Lacuna->db->resultset('Lacuna::DB::Result::AIScratchPad')->search({
            ai_empire_id    => $self->empire_id,
            body_id         => 0,
        });

        return $scratch;
    }
);

sub next_viable_colony {
    my $self = shift;
    return $self->viable_colonies->search(undef, { order_by => 'rand()' })->first;
}

sub create_empire {
    my $self = shift;
    say 'Founding Empire';
    my %attributes = (
        %{$self->empire_defaults},
        id                  => $self->empire_id,
        stage               => 'founded',
        date_created        => DateTime->now,
        password            => Lacuna::DB::Result::Empire->encrypt_password(rand(99999999)),
        university_level    => 30,
    );
    my $db      = Lacuna->db;
    my $empire  = $db->resultset('Lacuna::DB::Result::Empire')->new(\%attributes)->insert;
#    my $zone    = $db->resultset('Lacuna::DB::Result::Map::Body')->get_column('zone')->max;
#    my $home    = $self->viable_colonies->search({zone => $zone})->first;
    my $home    = $self->viable_colonies->search(undef,{ order_by => 'rand()'})->first;
    my @to_demolish = @{$home->building_cache};
    $home->delete_buildings(\@to_demolish);
    $empire->found($home);
    $self->build_colony($home);
    return $empire;
}

sub build_colony {
    my ($self,$body) = @_;    
    
    say 'Upgrading PCC';
    my $pcc = $body->command;
    $pcc->level(15);
    $pcc->update;
    my $decor   = [qw(
        Lacuna::DB::Result::Building::Permanent::Beach1
        Lacuna::DB::Result::Building::Permanent::Beach2
        Lacuna::DB::Result::Building::Permanent::Beach3
        Lacuna::DB::Result::Building::Permanent::Beach4
        Lacuna::DB::Result::Building::Permanent::Beach5
        Lacuna::DB::Result::Building::Permanent::Beach6
        Lacuna::DB::Result::Building::Permanent::Beach7
        Lacuna::DB::Result::Building::Permanent::Beach8
        Lacuna::DB::Result::Building::Permanent::Beach9
        Lacuna::DB::Result::Building::Permanent::Beach10
        Lacuna::DB::Result::Building::Permanent::Beach11
        Lacuna::DB::Result::Building::Permanent::Beach12
        Lacuna::DB::Result::Building::Permanent::Beach13
        Lacuna::DB::Result::Building::Permanent::Crater
        Lacuna::DB::Result::Building::Permanent::Grove
        Lacuna::DB::Result::Building::Permanent::Lagoon
        Lacuna::DB::Result::Building::Permanent::Lake
        Lacuna::DB::Result::Building::Permanent::RockyOutcrop
        Lacuna::DB::Result::Building::Permanent::Sand
        Lacuna::DB::Result::Building::PlanetaryCommand
    )];
    foreach my $building (@{$body->building_cache}) {
        unless ( grep { $building->class eq $_ } @{$decor}) {
            $building->delete;
        }
    }

    say 'Placing structures on '.$body->name;
    my @plans = $self->colony_structures;
    
    my $extras = $self->extra_glyph_buildings;

    my @findable;
    
    if ($extras->{quantity}) {
        push @findable, @{$extras->{findable}};
        foreach (1..$extras->{quantity}) {
            push @plans, [$findable[rand @findable], randint($extras->{min_level}, $extras->{max_level})];
        }
    }
    
    my $buildings = Lacuna->db->resultset('Lacuna::DB::Result::Building');
    foreach my $plan (@plans) {
        my ($x, $y) = $body->find_free_space;
        my $building = $buildings->new({
            class   => $plan->[0],
            level   => $plan->[1] - 1,
            x       => $x,
            y       => $y,
            body_id => $body->id,
            body    => $body,
        });
        say $building->name;
        $body->build_building($building);
        $building->finish_upgrade;
    }
}

sub run_all_hourly_colony_updates {
    my $self = shift;
    my $colonies = $self->empire->planets;
    while (my $colony = $colonies->next) {
        say '###############';
        say '#### UPDATE COLONY : '.$colony->name;
        say '###############';

        $colony->tick;
        $self->run_hourly_colony_updates($colony);
    }
}

sub run_all_hourly_empire_updates {
    my $self = shift;
    say '###############';
    say '#### UPDATE EMPIRE ';
    say '###############';
    $self->run_hourly_empire_updates($self->empire);
}


sub add_colonies {
    my ($self, $add_one) = @_;
    my $config = Lacuna->config;
    my $empire = $self->empire;
    
    say 'getting existing colonies';
    my $colonies = $empire->planets;
    my @existing_zones = $colonies->get_column('zone')->all;
    say 'getting neutral zones';
    my $na_param = Lacuna->config->get('neutral_area');
    my @neutral_zones = ();
    if ($na_param->{zone}) {
      @neutral_zones = @{$na_param->{zone_list}};
    }
    
    say 'Adding colonies...';
    X: foreach my $x (int($config->get('map_size/x')->[0]/250) .. int($config->get('map_size/x')->[1]/250)) {
        Y: foreach my $y (int($config->get('map_size/y')->[0]/250) .. int($config->get('map_size/y')->[1]/250)) {
            my $zone = $x.'|'.$y;
            next if ($zone ~~ \@neutral_zones);
            say $zone;
            if ($zone ~~ \@existing_zones) {
                say "nothing needed";
            }
            else {
                say 'Finding colony in '.$zone.'...';
# Need to narrow search if neutral area defined by coordinates.
                my @bodies = $self->viable_colonies->search({
                            'me.zone' => $zone,
                            'stars.station_id'   => undef,
                         },{
                           join       => 'stars',
                           rows       => 100,
                           order_by => 'rand()'
                   });
                my $body = random_element(\@bodies);

                if (defined $body) {
                    say 'Clearing '.$body->name;
                    my @to_demolish = @{$body->building_cache};
                    $body->delete_buildings(\@to_demolish);
                    say 'Colonizing '.$body->name;
                    $body->found_colony($empire);
                    $self->build_colony($body);
                    last X if $add_one;
                }
                else {
                    say 'Could not find a colony to occupy.';
                }
            }
        }
    }
}

sub run_missions {
    my ($self, $colony) = @_;
    say 'RUN MISSIONS';
    my @missions = $self->spy_missions;
    my $mission = $missions[rand @missions];
    my $infiltrated_spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({from_body_id => $colony->id, on_body_id => {'!=', $colony->id}});
    while (my $spy = $infiltrated_spies->next) {
        next if $spy->task eq "Sabotage BHG";
        if ($spy->is_available) {
            if ($spy->on_body->id != $spy->from_body->id and $spy->on_body->in_neutral_area ) {
# Check if spy is in neutral zone, if it is, send someone to fetch?
                say "    Spy ID: ".$spy->id." escaping from neutral zone...";
                my $result = eval{$spy->assign("Bugout")};
                say "        ".$result->{result};
            }
            else {
                say "    Spy ID: ".$spy->id." running mission...";
                my $result = eval{$spy->assign($mission)};
                say "        ".$result->{result};
            }
        }
        else {
            say "    Spy ID: ".$spy->id." not available";
        }
    }
}


sub repair_buildings {
    my ($self, $colony) = @_;
    say 'REPAIR DAMAGED BUILDINGS';
    foreach my $building (@{$colony->building_cache}) {
        if ($building->efficiency < 100) {
            say "    ".$building->name." needs repairing";
            my $costs = $building->get_repair_costs;
            my $can = eval{$building->can_repair($costs)};
            my $reason = $@;
            if ($can) {
                $building->repair($costs);
                say "        repaired";
            }
            else {
                say "        ".$reason->[1];
            }
        }
    }
}

sub demolish_bleeders {
  my ($self, $colony) = @_;
  say 'DEMOLISH BLEEDERS';
  my @bleeders = $colony->get_buildings_of_class('Lacuna::DB::Result::Building::DeployedBleeder');
  foreach my $bleeder (@bleeders) {
    if (randint(0,9) < 5) {
      say '    missed bleeder';
    }
    else {
      say '    demolish bleeder';
      $bleeder->demolish;
    }
  }
}

sub pod_check {
  my ($self, $colony, $pod_level) = @_;
  return if (Lacuna->cache->get('supply_pod_sent',$colony->id));
  my $food_stored = 0; my $ore_stored = 0;
  my @food = map { $_.'_stored' } FOOD_TYPES;
  my @ore  = map { $_.'_stored' } ORE_TYPES;
  my $attrib;
  for $attrib (@food) { $food_stored += $colony->$attrib; }
  for $attrib (@ore)  { $ore_stored  += $colony->$attrib; }
  if ($food_stored <= 0 or $ore_stored <= 0 or
      $colony->water_stored <= 0 or $colony->energy_stored <= 0) {
    say 'DEPLOY SUPPLY POD';
    my ($x, $y) = eval{ $colony->find_free_space };
# Check to see if spot found, if not, clear off a crater if found.
    unless ($@) {
      my $deployed = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        class       => 'Lacuna::DB::Result::Building::SupplyPod',
        x           => $x,
        y           => $y,
        level       => $pod_level - 1,
        body_id     => $colony->id,
        body        => $colony,
      });
      say $deployed->name;
      $colony->build_building($deployed, 1);
      $deployed->finish_upgrade;
      Lacuna->cache->set('supply_pod_sent',$colony->id,1,60*60*24);
    }
    else {
      my @craters = $colony->get_buildings_of_class('Lacuna::DB::Result::Building::Permanent::Crater');
      if (@craters) {
        my $crater =  random_element \@craters;
        say 'DEMOLISH CRATER';
        $crater->demolish;
      }
    }
    $colony->recalc_stats;
    my $add_it = $colony->water_capacity  - $colony->water_stored;
    say "Adding Water: $add_it";
    $colony->add_type("water",  $add_it);
    $add_it = $colony->energy_capacity  - $colony->energy_stored;
    say "Adding Energy: $add_it";
    $colony->add_type("energy", $add_it);
    my $food_room = $colony->food_capacity - $food_stored;
    say "Adding Food: $food_room";
    my $ore_room = $colony->ore_capacity - $ore_stored;
    say "Adding Ore: $ore_room";
    my @foods = shuffle FOOD_TYPES;
    my @ores  = shuffle ORE_TYPES;
    my @food_type = splice(@foods, 0, 4);
    my @ore_type  = splice(@ores,  0, 4);
    for my $food (@food_type) {
      $colony->add_type("$food", int($food_room/4));
    }
    for my $ore (@ore_type) {
      $colony->add_type("$ore", int($ore_room/4));
    }
  }
  $colony->update;
}

sub train_spies {
    my ($self, $colony, $chance, $subsidise ) = @_;
    say 'TRAIN SPIES';

    my $intelligence = $colony->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');

    return unless defined $intelligence;

    my $costs = $intelligence->training_costs;
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({
            from_body_id => $colony->id,
        })->count;
    my $max_spies = $intelligence->level * 3;
    my $room_for  = $max_spies - $spies;
    my $train_count = 0;
    if ($subsidise) {
        my $deception = $colony->empire->deception_affinity * 50;
        while ($train_count < $room_for) {
            $train_count++;
            next if (rand(100) < $chance);
            # bypass everything and just create the spy
            my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->new({
                from_body_id    => $colony->id,
                on_body_id      => $colony->id,
                task            => 'Idle',
                started_assignment  => DateTime->now,
                available_on    => DateTime->now,
                empire_id       => $colony->empire_id,
                offense         => ($intelligence->espionage_level * 75) + $deception,
                defense         => ($intelligence->security_level * 75) + $deception,
                intel_xp        => randint(10,400),
                mayhem_xp       => randint(10,400),
                politics_xp     => randint(10,400),
                theft_xp        => randint(10,400),
            })
            ->update_level
            ->insert;

            say "    Subsidised spy being trained";
            $spies++;
        }
    }
    else {
        my $can_train = 1;

        while ($can_train and $train_count < $room_for) {
            $train_count++;
            next if (rand(100) < $chance);
            my $can = eval{$intelligence->can_train_spy($costs)};
            my $reason = $@;
            if ($can) {
                $intelligence->spend_resources_to_train_spy($costs);
                $intelligence->train_spy($costs->{time});
                say "    Spy being trained.";
            }
            else {
                say '    '.$reason->[1];
                $can_train = 0;
            }
        }
    }
}


sub build_ships {
    my ($self, $colony) = @_;
    say 'BUILD SHIPS';
    if ($colony->happiness < -1_000_000) {
        say "Too unhappy to build ships.";
        return;
    }
    my @shipyards = sort {$a->work_ends cmp $b->work_ends} $colony->get_buildings_of_class('Lacuna::DB::Result::Building::Shipyard');
    my @priorities = $self->ship_building_priorities($colony);
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    foreach my $priority (@priorities) {
        say $priority->[0];
        my $count = $ships->search({body_id => $colony->id, type => $priority->[0]})->count;
        if ($count < $priority->[1]) {
            my $shipyard = shift @shipyards;
            $shipyard->body($colony);
            my $ship = $ships->new({type => $priority->[0]});
            my $costs = $shipyard->get_ship_costs($ship);
            my $can = eval{$shipyard->can_build_ship($ship, $costs)};
			my $reason = $@;
            if ($can) {
                say "building ".$ship->type;
                $shipyard->spend_resources_to_build_ship($costs);
                $shipyard->build_ship($ship, $costs->{seconds});
            }
            else {
                say $reason->[1];
            }
            push @shipyards, $shipyard;
        }
        else {
            say "have enough";
        }
    }
}

# Fill the shipyards as full as they can be
sub build_ships_max {
    my ($self, $colony) = @_;
    say 'BUILD SHIPS';
    if ($colony->happiness < -1_000_000) {
        say "Too unhappy to build ships.";
        return;
    }
    my @ship_yards  = sort {$a->work_ends cmp $b->work_ends} $colony->get_buildings_of_class('Lacuna::DB::Result::Building::Shipyard');
    my $ships 	    = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    my $ship_yard   = shift @ship_yards;
    my $free_docks  = $ship_yard->level - $ships->search({shipyard_id => $ship_yard->id, task => 'Building'});
    my @priorities  = $self->ship_building_priorities($colony);
    SHIP:
    for my $priority (@priorities) {
        my ($ship_type,$quota) = @$priority;

        my $no_of_ships = $ships->search({body_id => $colony->id, type => $ship_type})->count;
        my $ships_needed = $quota - $no_of_ships;
        if ($ships_needed <= 0) {
            say "    quota met for $ship_type";
        }
        while ($ships_needed > 0) {
            # loop around filling shipyards one at a time until either there are no more
            # shipyards or we need no more ships
            SHIP_YARD:
            while ($ships_needed > 0 and $ship_yard) {

                while ($free_docks <= 0) {
                    $ship_yard = shift @ship_yards;
                    last SHIP unless $ship_yard;
                    $free_docks  = $ship_yard->level - $ships->search({shipyard_id => $ship_yard->id, task => 'Building'});
                }
                my $ship = $ships->new({type => $ship_type});
                my $costs = $ship_yard->get_ship_costs($ship);
                my $can_build = eval{$ship_yard->can_build_ship($ship, $costs)};
                my $reason = $@;
                if ($can_build) {
                    say "    building ".$ship->type;
                    $ship_yard->spend_resources_to_build_ship($costs);
                    $ship_yard->build_ship($ship, $costs->{seconds});
                }
                else {
                    say "    ".$reason->[1];
                    next SHIP;
                }
                $ships_needed--;
                $free_docks--;
            }
        }
    }
}

sub set_defenders {
    my ($self, $colony) = @_;
    say 'SET DEFENDERS';
    my $local_spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({from_body_id => $colony->id, on_body_id => $colony->id});
    my $on_sweep = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({from_body_id => $colony->id, on_body_id => $colony->id, task => "Security Sweep"})->count;
    my $enemies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({on_body_id => $colony->id, task => { '!=' => 'Captured'}, empire_id => { '!=' => $self->empire_id }})->count;
    $on_sweep = 10 if ($enemies == 0);
    while (my $spy = $local_spies->next) {
        if ($spy->is_available) {
            if ($spy->task eq 'Security Sweep' or $on_sweep < 10) {
                say "    Spy ID: ".$spy->id." sweeping";
                my $spy_result = $spy->assign('Security Sweep');
                $spy->update;
                if ($spy_result->{message_id}) {
                    my $message = Lacuna->db->resultset('Lacuna::DB::Result::Message')->find($spy_result->{message_id});
                    say "message: ".$message->subject;
                    if ($message && $message->subject eq "Spy Report") {
                        $on_sweep += 10; #No spies to find
                        say "        spy report, no more sweeps.";
                    }
                    elsif ($message && $message->subject eq "Enemy Captured") {
                        $on_sweep--;
                        say "        caught someone, more sweeps.";
                    }
                }
                $on_sweep++;
            }
            elsif ($spy->task ne 'Counter Espionage') {
                say "    Spy ID: ".$spy->id." setting to defend";
                $spy->task('Counter Espionage');
                $spy->update;
            }
        }
        else {
            say "    Spy ID: ".$spy->id." is currently unavailable";
        }
    }
}

sub kill_prisoners {
    my ($self, $colony, $when) = @_;
#When is in hours from prisoner being released.

    say 'KILL PRISONERS';
    my $prisoners = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({on_body_id => $colony->id, task => 'Captured', empire_id => { '!=' => $self->empire_id }});
    my $now = DateTime->now;
    my $prisoner_cnt = 0;
    while (my $prisoner = $prisoners->next) {
        my $sentence = $now->subtract_datetime_absolute($prisoner->available_on);
        my $hours = int($sentence->seconds/(60*60));
        if ($hours < $when) {
            $prisoner->empire->send_predefined_message(
                from        => $colony->empire,
                tags        => ['Spies','Alert'],
                filename    => 'spy_executed.txt',
                params      => [$prisoner->name, $prisoner->from_body->id, $prisoner->from_body->name, $colony->x, $colony->y, $colony->name, $colony->empire->id, $colony->empire->name],
            );
            $prisoner->delete;
            $prisoner_cnt++;
        }
    }
    say $prisoner_cnt." prisoners executed.";
}

sub start_attack {
    my ($self, $attacking_colony, $target_colony, $ship_types) = @_;
    say 'LOOK FOR PROBES';
    my $attack = AnyEvent->condvar;
    my $db = Lacuna->db;
    my $seconds = 0;
    my $count = $db->resultset('Lacuna::DB::Result::Probes')->search({ empire_id => $self->empire_id, star_id => $target_colony->star_id })->count;
    if ($count) {
        say '    Has one at star already...';
        $seconds = 1;
    }
    my $probe = $db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $attacking_colony->id, type => 'probe', task=>'Docked'})->first;
    if (defined $probe and $seconds == 0) {
        say '    Has a probe to launch for '.$target_colony->name.'...';
        $probe->send(target => $target_colony->star);
        $seconds = $probe->date_available->epoch - time();
        say '    Probe will arrive in '.$seconds.' seconds.';
    }
    if ($seconds) {
        my $timer; $timer = AnyEvent->timer(
            after   => $seconds,
            cb      => sub {
                $self->attack_with_ships($attacking_colony, $target_colony, $ship_types);
                $attack->send;
                undef $timer;
            },
        );
        return $attack;
    }
    else {
        say '    No probe. Cancel assault.';
        $attack->send;
        return $attack;
    }
}

sub attack_with_ships {
    my ($self, $attacking_colony, $target_colony, $ship_types) = @_;
    say 'ATTACK WITH SHIPS';
    my $available_ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ type => { in => $ship_types }, task=>'Docked', body_id => $attacking_colony->id});
    while (my $ship = $available_ships->next) {
        if (eval{$ship->can_send_to_target($target_colony)}) {
            sleep(randint(1,10)); # simulate regular player clicking
            say '    Sending '.$ship->type_formatted.' to '.$target_colony->name.'...';
            $ship->send(target => $target_colony);
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
