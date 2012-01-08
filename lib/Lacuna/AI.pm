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
    return $self->viable_colonies->search(undef, { rows => 1, order_by => 'rand()' })->single;
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
    my $zone    = $db->resultset('Lacuna::DB::Result::Map::Body')->get_column('zone')->max;
    my $home    = $self->viable_colonies->search({zone => $zone},{rows=>1})->single;
    $home->buildings->delete_all;
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

    say 'Placing structures on '.$body->name;
    my @plans = $self->colony_structures;
    
    my @findable;
    foreach my $module (findallmod Lacuna::DB::Result::Building::Permanent) {
        push @findable, $module unless $module =~ m/Platform$/ || $module =~ m/Beach/;
    }
    
    my $extras = $self->extra_glyph_buildings;
    if ($extras->{quantity}) {
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
    
    say 'Adding colonies...';
    X: foreach my $x (int($config->get('map_size/x')->[0]/250) .. int($config->get('map_size/x')->[1]/250)) {
        Y: foreach my $y (int($config->get('map_size/y')->[0]/250) .. int($config->get('map_size/y')->[1]/250)) {
            my $zone = $x.'|'.$y;
            next if $zone eq '-3|0';
            say $zone;
            if ($zone ~~ \@existing_zones) {
                say "nothing needed";
            }
            else {
                say 'Finding colony in '.$zone.'...';
                my $body = $self->viable_colonies->search({zone => $zone},{rows=>1})->single;
                if (defined $body) {
                    say 'Clearing '.$body->name;
                    $body->buildings->delete_all;
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
        if ($spy->is_available) {
            say "    Spy ID: ".$spy->id." running mission...";
            my $result = eval{$spy->assign($mission)};
            say "        ".$result->{result};
        }
        else {
            say "    Spy ID: ".$spy->id." not available";
        }
    }
}


sub repair_buildings {
    my ($self, $colony) = @_;
    say 'REPAIR DAMAGED BUILDINGS';
    my $buildings = $colony->buildings;
    while (my $building = $buildings->next) {
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
    if (randint(0,9) < 2) {
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
        my $crater =  random_element @craters;
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

# empires can have more spies now than their intelligence ministry could
# normally supply. Put a limit of 3 times the level of the Intelligence ministry
# if 'subsidise' is set
#
sub train_spies {
    my ($self, $colony, $subsidise) = @_;
    say 'TRAIN SPIES';

    my $intelligence = $colony->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');

    return unless defined $intelligence;

    my $costs = $intelligence->training_costs;
    if ($subsidise) {
        my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({
            from_body_id => $colony->id,
        })->count;
        my $max_spies = $intelligence->level;
        my $deception = $colony->empire->deception_affinity * 50;
        while ($spies < $max_spies * 3) {
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
                intel_xp        => randint(10,40),
                mayhem_xp       => randint(10,40),
                politics_xp     => randint(10,40),
                theft_xp        => randint(10,40),
            })
            ->update_level
            ->insert;

            say "    Subsidised spy being trained";
            $spies++;
        }
    }
    else {
        my $can_train = 1;

        while ($can_train) {
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
    my @shipyards = $colony->get_buildings_of_class('Lacuna::DB::Result::Building::Shipyard')->search(undef,{order_by => 'work_ends'})->all;
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
    my @ship_yards  = $colony->get_buildings_of_class('Lacuna::DB::Result::Building::Shipyard')->search(undef,{order_by => 'work_ends'})->all;
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
    while (my $spy = $local_spies->next) {
        if ($spy->is_available) {
            if ($spy->task ne 'Counter Espionage') {
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
    my $probe = $db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $attacking_colony->id, type => 'probe', task=>'Docked'},{rows => 1})->single;
    if (defined $probe) {
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
