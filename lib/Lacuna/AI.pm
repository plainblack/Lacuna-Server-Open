package Lacuna::AI;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Lacuna::Util qw(randint);
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
        say 'Colony: '.$colony->name;
        $colony->tick;
        $self->run_hourly_colony_updates($colony);
    }
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
    say 'Running missions...';
    my @missions = $self->spy_missions;
    my $mission = $missions[rand @missions];
    my $infiltrated_spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({from_body_id => $colony->id, on_body_id => {'!=', $colony->id}});
    while (my $spy = $infiltrated_spies->next) {
        say $spy->id;
        if ($spy->is_available) {
            say "running mission...";
            my $result = eval{$spy->assign($mission)};
            say $result->{result};
        }
        else {
            say "not available";
        }
    }
}


sub repair_buildings {
    my ($self, $colony) = @_;
    say 'Repairing damaged buildings...';
    my $buildings = $colony->buildings;
    while (my $building = $buildings->next) {
        say $building->name;
        if ($building->efficiency < 100) {
            my $costs = $building->get_repair_costs;
			my $can = eval{$building->can_repair($costs)};
			my $reason = $@;
			if ($can) {
                $building->repair($costs);
                say "repaired";
            }
            else {
                say $reason->[1];
            }
        }
        else {
            say "does not need to be repaired";
        }
    }
}

sub demolish_bleeders {
    my ($self, $colony) = @_;
    say 'Demolishing bleeders';
    my @bleeders = $colony->get_buildings_of_class('Lacuna::DB::Result::Building::DeployedBleeder');
    foreach my $bleeder (@bleeders) {
        $bleeder->demolish;
    }
}


sub train_spies {
    my ($self, $colony) = @_;
    say 'Training spies...';
    my $intelligence = $colony->get_building_of_class('Lacuna::DB::Result::Building::Intelligence');
    if (defined $intelligence) {
        my $can_train = 1;

        while ($can_train) {
            my $costs = $intelligence->training_costs;
            my $can = eval{$intelligence->can_train_spy($costs)};
            my $reason = $@;
            if ($can) {
                $intelligence->spend_resources_to_train_spy($costs);
                $intelligence->train_spy($costs->{time});
                say "Spy trained.";
            }
            else {
                say $reason->[1];
                $can_train = 0;
            }
        }
    }
}


sub build_ships {
    my ($self, $colony) = @_;
    say 'Building ships...';
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
    say 'Building ships...';
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
            say "quota met for $ship_type";
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
                    say "building ".$ship->type;
                    $ship_yard->spend_resources_to_build_ship($costs);
                    $ship_yard->build_ship($ship, $costs->{seconds});
                }
                else {
                    say $reason->[1];
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
    say 'Setting defenders...';
    my $local_spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({from_body_id => $colony->id, on_body_id => $colony->id});
    while (my $spy = $local_spies->next) {
        say $spy->id;
        if ($spy->is_available) {
            if ($spy->task eq 'Counter Espionage') {
                say "already defending";
            }
            else {
                say "setting defender";
                $spy->task('Counter Espionage');
                $spy->update;
            }
        }
        else {
            say "unavailable";
        }
    }
}

sub start_attack {
    my ($self, $attacking_colony, $target_colony, $ship_types) = @_;
    say 'Looking for probes...';
    my $attack = AnyEvent->condvar;
    my $db = Lacuna->db;
    my $seconds = 0;
    my $count = $db->resultset('Lacuna::DB::Result::Probes')->search({ empire_id => $self->empire_id, star_id => $target_colony->star_id })->count;
    if ($count) {
        say 'Has one at star already...';
        $seconds = 1;
    }
    my $probe = $db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $attacking_colony->id, type => 'probe', task=>'Docked'},{rows => 1})->single;
    if (defined $probe) {
        say 'Has a probe to launch for '.$target_colony->name.'...';
        $probe->send(target => $target_colony->star);
        $seconds = $probe->date_available->epoch - time();
        say 'Probe will arrive in '.$seconds.' seconds.';
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
        say 'No probe. Cancel assault.';
        $attack->send;
        return $attack;
    }
}

sub attack_with_ships {
    my ($self, $attacking_colony, $target_colony, $ship_types) = @_;
    say 'Attack!';
    my $available_ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ type => { in => $ship_types }, task=>'Docked', body_id => $attacking_colony->id});
    while (my $ship = $available_ships->next) {
        if (eval{$ship->can_send_to_target($target_colony)}) {
            sleep(randint(1,10)); # simulate regular player clicking
            say 'Sending '.$ship->type_formatted.' to '.$target_colony->name.'...';
            $ship->send(target => $target_colony);
        }
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;
