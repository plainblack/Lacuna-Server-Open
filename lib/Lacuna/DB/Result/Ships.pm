package Lacuna::DB::Result::Ships;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date randint);
use DateTime;
use Scalar::Util qw(weaken);
use feature "switch";

has 'hostile_action' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_build_hostile_action',
);

sub _build_hostile_action { 0 }

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('ships');
__PACKAGE__->add_columns(
    body_id                 => { data_type => 'int', is_nullable => 0 },
    shipyard_id             => { data_type => 'int', is_nullable => 0 },
    date_started            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    date_available          => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    type                    => { data_type => 'varchar', size => 30, is_nullable => 0 }, # Look at typecast_map below
    task                    => { data_type => 'varchar', size => 30, is_nullable => 0 }, # Building, Defend, Docked, Mining, Orbiting, Supply Chain, Travelling, Waiting on Trade, and Waste Chain
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    speed                   => { data_type => 'int', is_nullable => 0 },
    stealth                 => { data_type => 'int', is_nullable => 0 },
    combat                  => { data_type => 'int', is_nullable => 0 },
    hold_size               => { data_type => 'int', is_nullable => 0 },
    payload                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
    roundtrip               => { data_type => 'bit', default_value => 0 },
    direction               => { data_type => 'varchar', size => 3, is_nullable => 0 }, # in || out
    foreign_body_id         => { data_type => 'int', is_nullable => 1 },
    foreign_star_id         => { data_type => 'int', is_nullable => 1 },
    fleet_speed             => { data_type => 'int', is_nullable => 0 },
    berth_level             => { data_type => 'int', is_nullable => 0 },
    number_of_docks         => { data_type => 'int', is_nullable => 1 },
);
__PACKAGE__->typecast_map(type => {
    'attack_group'                          => 'Lacuna::DB::Result::Ships::AttackGroup', #attack ships combined into one group.
    'probe'                                 => 'Lacuna::DB::Result::Ships::Probe',
    'stake'                                 => 'Lacuna::DB::Result::Ships::Stake',
    'supply_pod'                            => 'Lacuna::DB::Result::Ships::SupplyPod',
    'supply_pod2'                           => 'Lacuna::DB::Result::Ships::SupplyPod2',
    'supply_pod3'                           => 'Lacuna::DB::Result::Ships::SupplyPod3',
    'supply_pod4'                           => 'Lacuna::DB::Result::Ships::SupplyPod4',
    'supply_pod5'                           => 'Lacuna::DB::Result::Ships::SupplyPod5',
    'placebo'                               => 'Lacuna::DB::Result::Ships::Placebo',
    'placebo2'                              => 'Lacuna::DB::Result::Ships::Placebo2',
    'placebo3'                              => 'Lacuna::DB::Result::Ships::Placebo3',
    'placebo4'                              => 'Lacuna::DB::Result::Ships::Placebo4',
    'placebo5'                              => 'Lacuna::DB::Result::Ships::Placebo5',
    'placebo6'                              => 'Lacuna::DB::Result::Ships::Placebo6',
    'short_range_colony_ship'               => 'Lacuna::DB::Result::Ships::ShortRangeColonyShip',
    'colony_ship'                           => 'Lacuna::DB::Result::Ships::ColonyShip',
    'spy_pod'                               => 'Lacuna::DB::Result::Ships::SpyPod',
    'cargo_ship'                            => 'Lacuna::DB::Result::Ships::CargoShip',
    'space_station'                         => 'Lacuna::DB::Result::Ships::SpaceStation',
    'smuggler_ship'                         => 'Lacuna::DB::Result::Ships::SmugglerShip',
    'mining_platform_ship'                  => 'Lacuna::DB::Result::Ships::MiningPlatformShip',
    'terraforming_platform_ship'            => 'Lacuna::DB::Result::Ships::TerraformingPlatformShip',
    'gas_giant_settlement_ship'             => 'Lacuna::DB::Result::Ships::GasGiantSettlementPlatformShip',
    'scanner'                               => 'Lacuna::DB::Result::Ships::Scanner',
    'surveyor'                              => 'Lacuna::DB::Result::Ships::Surveyor',
    'detonator'                             => 'Lacuna::DB::Result::Ships::Detonator',
    'excavator'                             => 'Lacuna::DB::Result::Ships::Excavator',
    'scow'                                  => 'Lacuna::DB::Result::Ships::Scow',
    'scow_large'                            => 'Lacuna::DB::Result::Ships::ScowLarge',
    'scow_mega'                             => 'Lacuna::DB::Result::Ships::ScowMega',
    'scow_fast'                             => 'Lacuna::DB::Result::Ships::ScowFast',
    'freighter'                             => 'Lacuna::DB::Result::Ships::Freighter',
    'dory'                                  => 'Lacuna::DB::Result::Ships::Dory',
    'barge'                                 => 'Lacuna::DB::Result::Ships::Barge',
    'galleon'                               => 'Lacuna::DB::Result::Ships::Galleon',
    'hulk'                                  => 'Lacuna::DB::Result::Ships::Hulk',
    'hulk_huge'                             => 'Lacuna::DB::Result::Ships::HulkHuge',
    'hulk_fast'                             => 'Lacuna::DB::Result::Ships::HulkFast',
    'snark'                                 => 'Lacuna::DB::Result::Ships::Snark',
    'snark2'                                => 'Lacuna::DB::Result::Ships::Snark2',
    'snark3'                                => 'Lacuna::DB::Result::Ships::Snark3',
    'spy_shuttle'                           => 'Lacuna::DB::Result::Ships::SpyShuttle',
    'drone'                                 => 'Lacuna::DB::Result::Ships::Drone',
    'fighter'                               => 'Lacuna::DB::Result::Ships::Fighter',
    'sweeper'                               => 'Lacuna::DB::Result::Ships::Sweeper',
    'bleeder'                               => 'Lacuna::DB::Result::Ships::Bleeder',
    'thud'                                  => 'Lacuna::DB::Result::Ships::Thud',
    'observatory_seeker'                    => 'Lacuna::DB::Result::Ships::ObservatorySeeker',
    'spaceport_seeker'                      => 'Lacuna::DB::Result::Ships::SpacePortSeeker',
    'security_ministry_seeker'              => 'Lacuna::DB::Result::Ships::SecurityMinistrySeeker',
    'fissure_sealer'                        => 'Lacuna::DB::Result::Ships::FissureSealer',
});

with 'Lacuna::Role::Container';

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');
__PACKAGE__->belongs_to('foreign_star', 'Lacuna::DB::Result::Map::Star', 'foreign_star_id');
__PACKAGE__->belongs_to('foreign_body', 'Lacuna::DB::Result::Map::Body', 'foreign_body_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_shiptype', fields => ['type']);
}

use constant prereq                 => [ { class=> 'Lacuna::DB::Result::Building::University',  level => 1 } ];
use constant base_food_cost         => 1;
use constant base_water_cost        => 1;
use constant base_energy_cost       => 1;
use constant base_ore_cost          => 1;
use constant base_time_cost         => 1;
use constant base_waste_cost        => 1;
use constant base_speed             => 1;
use constant base_combat            => 0;
use constant base_stealth           => 0;
use constant base_hold_size         => 0;
use constant base_berth_level       => 1;
use constant pilotable              => 0;
use constant target_building        => [];
use constant build_tags             => [];
use constant splash_radius          => 0;

sub max_occupants {
    my $self = shift;
    return 0 unless $self->pilotable;
    return int($self->hold_size / 350);
}

before delete => sub {
    my ($self) = @_;

    # delete any arrival or finish_construction jobs
    #
    my $schedule_rs = Lacuna->db->resultset('Schedule')->search({
        parent_table    => 'Ships',
        parent_id       => $self->id,
    });
    while (my $schedule = $schedule_rs->next) {
        $schedule->delete;
    }
};

before task => sub {
    my ($self, $arg) = @_;

    if ($arg) {
        # to be safe, if a ship changes *from* either 'Travelling' or 'Building' we
        # delete any Schedule (and hence any beanstalk job) for it.
        # 
        if (($self->task eq 'Travelling' or $self->task eq 'Building') and $arg ne $self->task) {
            # Then we need to delete the 'schedule' and beanstalk job
            my $schedule_rs = Lacuna->db->resultset('Schedule')->search({
                parent_table    => 'Ships',
                parent_id       => $self->id,
            });
            while (my $schedule = $schedule_rs->next) {
                $schedule->delete;
            }
        }
    }
};

before date_available => sub {
    my ($self, $arg) = @_;

    if ($arg and $self->id) {
        $self->re_schedule($arg);
    }
};

# Change the date_available of the ship
sub re_schedule {
    my ($self, $date_available) = @_;

    my $schedule_rs = Lacuna->db->resultset('Schedule')->search({
        parent_table    => 'Ships',
        parent_id       => $self->id,
    });
    while (my $schedule = $schedule_rs->next) {
        my $new_schedule = Lacuna->db->resultset('Schedule')->create({
            parent_table    => 'Ships',
            queue           => $schedule->queue,
            parent_id       => $self->id,
            task            => $schedule->task,
            delivery        => $date_available,
        });
        $schedule->delete;
    }
}

sub arrive {
    my $self = shift;

    my ($schedule) = Lacuna->db->resultset('Schedule')->search({
        parent_table    => 'Ships',
        parent_id       => $self->id,
        task            => 'arrive',
    });
    $schedule->delete if defined $schedule;


    eval {
        # Throws exceptions to stop subsequent actions from happening
        $self->handle_arrival_procedures;
    };

    my $reason = $@;
    if (ref $reason eq 'ARRAY' && $reason->[0] eq -1) {
        # this is an expected exception, it means one of the roles took over
        return;
    }
    elsif ($reason) {
        # this is unexpected, so let's rethrow
        confess $reason;
    }
    
    # no exceptions, so we either need to go home or land
    if ($self->direction eq 'out') {
        $self->turn_around->update;
    }
    else {
        $self->land->update;
    }
}

sub handle_arrival_procedures {
    my $self = shift;
    $self->note_arrival;
}

sub note_arrival {
    my $self = shift;

    my $type = $self->type;
    if ($type eq "attack_group") {
        my $payload = $self->payload;
        for my $key (keys %{$payload->{fleet}}) {
            Lacuna->cache->increment($payload->{fleet}->{$key}->{type}.'_arrive_'.$self->foreign_body_id.$self->foreign_star_id,
                                     $self->body->empire_id,1, 60*60*24*30);
        }
    }
    else {
        Lacuna->cache->increment($type.'_arrive_'.$self->foreign_body_id.$self->foreign_star_id, $self->body->empire_id,1, 60*60*24*30);
    }
}

sub is_available {
    my ($self) = @_;
    return ($self->task eq 'Docked');
}

sub can_send_to_target {
    my $self = shift;
    unless ($self->task eq 'Docked') {
        confess [1010, 'That ship is busy.'];
    }
    return 1;
}

sub can_recall {
    my $self = shift;
    unless ($self->task ~~ [qw(Defend Orbiting)]) {
        confess [1010, 'That ship is busy.'];
    }
    return 1;
}

sub type_formatted {
    my $self = shift;

    return $self->type_human($self->type);
}

sub type_human {
    my ($self, $type) = @_;

    $type =~ s/_/ /g;
    $type =~ s/\b(\w)/\u$1/g;
    return $type;
}

sub date_started_formatted {
    my $self = shift;
    return format_date($self->date_started);
}

sub date_available_formatted {
    my $self = shift;
    return format_date($self->date_available);
}

sub get_status {
    my ($self, $target) = @_;
    my %status = (
        id              => $self->id,
        name            => $self->name,
        type_human      => $self->type_formatted,
        type            => $self->type,
        task            => $self->task,
        speed           => $self->speed,
        fleet_speed     => $self->fleet_speed,
        stealth         => $self->stealth,
        combat          => $self->combat,
        hold_size       => $self->hold_size,
        berth_level     => $self->berth_level,
        date_started    => $self->date_started_formatted,
        date_available  => $self->date_available_formatted,
        max_occupants   => $self->max_occupants,
        payload         => $self->format_description_of_payload,
        can_scuttle     => ($self->task eq 'Docked') ? 1 : 0,
        can_recall      => ($self->task ~~ [qw(Defend Orbiting)]) ? 1 : 0,
        number_of_docks => $self->number_of_docks,
    );
    if ($target) {
        $status{estimated_travel_time} = $self->calculate_travel_time($target);
    }
    if ($self->task eq 'Travelling') {
        my $body = $self->body;
        my $target = ($self->foreign_body_id) ? $self->foreign_body : $self->foreign_star;
        my $from = {
            id      => $body->id,
            name    => $body->name,
            type    => 'body',
        };
        my $to = {
            id      => $target->id,
            name    => $target->name,
            type    => (ref $target eq 'Lacuna::DB::Result::Map::Star') ? 'star' : 'body',
        };
        if ($self->direction ne 'out') {
            my $temp = $from;
            $from = $to;
            $to = $temp;
        }
        $status{to}             = $to;
        $status{from}           = $from;
        $status{date_arrives}   = $status{date_available};
    }
    elsif ($self->task ~~ [qw(Defend Orbiting)]) {
        my $body = $self->body;
        my $from = {
            id      => $body->id,
            name    => $body->name,
            type    => 'body',
        };
        my $orbiting = {
             id        => $self->foreign_body_id,
             name    => $self->foreign_body->name,
            type    => 'body',
            x        => $self->foreign_body->x,
            y        => $self->foreign_body->y,
        };
        $status{from} = $from;
        $status{orbiting} = $orbiting;
    }
    return \%status;
}

sub seconds_remaining {
    my $self = shift;
    return time - $self->date_available->epoch;
}

sub turn_around {
    my ($self, $fleet_speed) = @_;

    $self->direction( ($self->direction eq 'out') ? 'in' : 'out' );
    $self->fleet_speed($fleet_speed || 0);
    my $target = ($self->foreign_body_id) ? $self->foreign_body : $self->foreign_star;
    my $arrival = DateTime->now->add(seconds => $self->calculate_travel_time($target));
    $self->date_available($arrival);
    $self->date_started(DateTime->now);

    my $schedule = Lacuna->db->resultset('Schedule')->create({
        parent_table    => 'Ships',
        queue           => 'arrive_queue',
        parent_id       => $self->id,
        task            => 'arrive',
        delivery        => $arrival,
    });

    return $self;
}

sub send {
    my ($self, %options ) = @_;
    $self->date_started(DateTime->now);
    $self->task('Travelling');
    $self->payload($options{payload} || {});
    $self->roundtrip($options{roundtrip} || 0);
    $self->direction($options{direction} || 'out');
    my $arrival = $options{arrival} || DateTime->now->add(seconds=>$self->calculate_travel_time($options{target}));

    my $five_minute = DateTime->now->add(minutes=>5);
    if ($arrival < $five_minute) {
        $arrival = $five_minute;
    }

    my $two_months  = DateTime->now->add(days=>60);
    if ($arrival > $two_months) {
        confess [1009, "Cannot set a speed that will take over 60 days."];
    }

    $self->date_available($arrival);

    if ($options{target}->isa('Lacuna::DB::Result::Map::Body')) {
        $self->foreign_body_id($options{target}->id);
        $self->foreign_body($options{target});
        weaken($self->{_relationship_data}{foreign_body});
        $self->foreign_star_id(undef);
        $self->foreign_star(undef);
    }
    elsif ($options{target}->isa('Lacuna::DB::Result::Map::Star')) {
        $self->foreign_star_id($options{target}->id);
        $self->foreign_star($options{target});
        $self->foreign_body_id(undef);
        $self->foreign_body(undef);
    }
    else {
        confess [1002, 'You cannot send a ship to a non-existant target.'];
    }
    $self->update;

    my @ag_list = ("sweeper","snark","snark2","snark3",
                   "observatory_seeker","spaceport_seeker","security_ministry_seeker",
                   "scanner","surveyor","detonator","bleeder","thud",
                   "scow","scow_large","scow_fast","scow_mega", "attack_group");
    my $cnt = 0;
    my %ag_hash = map { $_ => $cnt++ } @ag_list;
    my $time2arrive = DateTime->now->subtract_datetime_absolute($arrival);
    my $seconds2arrive = $time2arrive->seconds;
    my $sec_rng = 900;
    if ($seconds2arrive < 1200) {
        $sec_rng = int($seconds2arrive * 2/3);
    }
    my $dtf = Lacuna->db->storage->datetime_parser;
    my $start_range = DateTime->now->add(seconds => ($seconds2arrive - $sec_rng));
    my $end_range = DateTime->now->add(seconds => ($seconds2arrive + $sec_rng));
    my $ships_rs;
    my $ag_chk = 0;
    if ($options{target}->isa('Lacuna::DB::Result::Map::Star')) {
        $ag_chk = 0; #Just an empty statement.
    }
    elsif ( grep { $self->type eq $_ } @ag_list ) {
        $ships_rs = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
            id      => { '!=' => $self->id },
            body_id => $self->body_id,
            foreign_body_id => $self->foreign_body_id,
            foreign_star_id => $self->foreign_star_id,
            direction => 'out',
            task    => 'Travelling',
            type => { 'in' => \@ag_list },
            date_available => { between => [ $dtf->format_datetime($start_range),
                                             $dtf->format_datetime($end_range) ] },
        });
        $ag_chk += $ships_rs->get_column('number_of_docks')->sum;
    }

    if ($seconds2arrive > 300 && $ag_chk > 1) {
        my $payload = $self->payload;
#        $payload->{debug} = {
#            old_type => $self->type,
#            count    => $ships_rs->count,
#            start_rng => $dtf->format_datetime($start_range),
#            end_rng => $dtf->format_datetime($end_range),
#            seconds => $seconds2arrive,
#        };
        if ($self->type eq "attack_group") { #Turn ship into attack group if not already one
#            $payload = $self->payload;
#            $payload->{debug}->{extra} = "already ag";
        }
        else {
            my $key = sprintf("%02d:%s:%05d:%05d:%05d:%09d",
                              $ag_hash{$self->type},
                              $self->type, 
                              $self->combat, 
                              $self->speed, 
                              $self->stealth, 
                              $self->hold_size);
            $payload->{fleet}->{$key} = {
                type      => $self->type, 
                speed     => $self->speed, 
                combat    => $self->combat, 
                stealth   => $self->stealth, 
                hold_size => $self->hold_size,
                target_building => $self->target_building,
                quantity  => 1,
            };
            $self->type("attack_group");
            $self->update;
        }
        my $date_available = $self->date_available;
        my $attack_group = {
            speed     => $self->speed, 
            stealth   => $self->stealth, 
            hold_size => $self->hold_size,
            combat    => $self->combat, 
            target_building => $self->target_building,
            number_of_docks => $self->number_of_docks,
        };
        while (my $ship = $ships_rs->next) {
            next if ($ship->id == $self->id);
            if ($ship->speed < $attack_group->{speed}) {
                $attack_group->{speed} = $ship->speed;
            }
            if ($ship->speed < $attack_group->{stealth}) {
                $attack_group->{stealth} = $ship->stealth;
            }
            $attack_group->{combat} += $ship->combat;
            $attack_group->{hold_size} += $ship->hold_size; #This really is only good for scows
            $attack_group->{number_of_docks} += $ship->number_of_docks;
            if ($ship->type eq "attack_group") {
                if ($ship->payload->{resources}->{waste}) {
                    if ($payload->{resources}->{waste}) {
                        $payload->{resources}->{waste} += $ship->payload->{resources}->{waste};
                    }
                    else {
                        $payload->{resources}->{waste} = $ship->payload->{resources}->{waste};
                    }
                }
                for my $key (keys %{$ship->payload->{fleet}}) {
                    if ($payload->{fleet}->{$key}) {
                        $payload->{fleet}->{$key}->{quantity} += $ship->payload->{fleet}->{$key}->{quantity};
                    }
                    else {
                        %{$payload->{fleet}->{$key}} = %{$ship->payload->{fleet}->{$key}};
                    }
                }
            }
            else {
                my $key = sprintf("%02d:%s:%05d:%05d:%05d:%09d",
                              $ag_hash{$ship->type},
                              $ship->type, 
                              $ship->combat, 
                              $ship->speed, 
                              $ship->stealth, 
                              $ship->hold_size);
                if ($payload->{fleet}->{$key}) {
                    $payload->{fleet}->{$key}->{quantity}++;
                }
                else {
                    $payload->{fleet}->{$key} = {
                        type      => $ship->type, 
                        speed     => $ship->speed, 
                        combat    => $ship->combat, 
                        stealth   => $ship->stealth, 
                        hold_size => $ship->hold_size,
                        target_building => $self->target_building,
                        quantity  => 1,
                    };
                }
            }
            if ($ship->date_available > $date_available) {
                $date_available = $ship->date_available;
            }
            $ship->delete;
        }
        $self->name("Attack Group Ship");
        $self->speed($attack_group->{speed});
        $self->combat($attack_group->{combat});
        $self->stealth($attack_group->{stealth});
        $self->payload($payload);
        $self->hold_size($attack_group->{hold_size});
        $self->number_of_docks($attack_group->{number_of_docks});
        $self->berth_level(1);
        $self->date_available($date_available);
        $self->update;
    }

    my $schedule = Lacuna->db->resultset('Schedule')->create({
        delivery        => $arrival,
        queue           => 'arrive_queue',
        parent_table    => 'Ships',
        parent_id       => $self->id,
        task            => 'arrive',
    });

    return $self;
}

sub start_construction {
    my ($self) = @_;

    my $schedule = Lacuna->db->resultset('Schedule')->create({
        delivery        => $self->date_available,
        parent_table    => 'Ships',
        parent_id       => $self->id,
        task            => 'finish_construction',
    });

    return $self;
}

sub finish_construction {
    my ($self) = @_;
    $self->body->empire->add_medal($self->type);
    $self->task('Docked');
    $self->date_available(DateTime->now);
    $self->update;

    my ($schedule) = Lacuna->db->resultset('Schedule')->search({
        parent_table    => 'Ships',
        parent_id       => $self->id,
        task            => 'finish_construction',
    });
    $schedule->delete if defined $schedule;

    return $self;
}

sub cancel_build {
    my ($self) = @_;

    if ($self->task eq 'Building') {
        $self->reschedule_queue;
        $self->delete;
    }
    return;
}


# Remove one ship from the build queue, reschedule all other following ships
#
sub reschedule_queue {
    my ($self) = @_;

    my $start_time = DateTime->now;
    my $ship_end_time;          # when the current ship completes
    my $building_time;          # The end time of the building working

    my @ships_queue = Lacuna->db->resultset('Ships')->search({
        task        => 'Building',
        shipyard_id => $self->shipyard_id,
    },{
        order_by    => { -asc => 'date_available'},
    })->all;

    my $ship;
    $building_time = DateTime->now;
    BUILD:
    while ($ship = shift @ships_queue) {
        $ship_end_time = $ship->date_available;
        if ($ship->id == $self->id) {
            last BUILD;
        }
        # Start time of the next ship is the end time of this one
        $start_time = $ship_end_time;
    }
    if ($ship) {
        # Remove this scheduled event
        my $duration = $ship_end_time->epoch - $start_time->epoch;
        # Don't bother to reschedule if it is a small period
        if ($duration > 5) {
            my ($schedule) = Lacuna->db->resultset('Schedule')->search({
                parent_table    => 'Ships',
                parent_id       => $self->id,
                task            => 'finish_construction',
            });
            $schedule->delete if defined $schedule;
            $building_time = $start_time;

            # Change the scheduled time for all subsequent builds (if any)
            while (my $ship = shift @ships_queue) {
                my $construction_ends = $ship->date_available->clone->subtract(seconds => $duration);
                $building_time = $construction_ends;

                $ship->date_available($construction_ends);
                $ship->update;
                Lacuna->db->resultset('Schedule')->reschedule({
                    parent_table    => 'Ships',
                    parent_id       => $ship->id,
                    task            => 'finish_construction',
                    delivery        => $construction_ends,
                });
            }
        }
    }
    # Set shipyard end time
    my $shipyard = Lacuna->db->resultset('Building')->find({ id => $self->shipyard_id });
    $shipyard->reschedule_work($building_time);
}


sub orbit {
    my ($self) = @_;
    $self->task('Orbiting');
    $self->date_available(DateTime->now);
    return $self;
}

sub defend {
    my ($self) = @_;
    $self->task('Defend');
    $self->date_available(DateTime->now);
    return $self;
}

sub land {
    my ($self) = @_;
    $self->task('Docked');
    $self->fleet_speed(0);
    $self->date_available(DateTime->now);
    $self->payload({});
    return $self;
}




# DISTANCE



sub calculate_travel_time {
    my ($self, $target) = @_;

    my $distance = $self->body->calculate_distance_to_target($target);
    my $speed = $self->speed;
    if ( $self->fleet_speed > 0 && $self->fleet_speed < $self->speed ) {
        $speed = $self->fleet_speed;
    }
    return $self->travel_time($self->body, $target, $speed);
}

sub travel_time {
    my ($class, $from, $target, $speed) = @_;

    my $distance = $from->calculate_distance_to_target($target);
    $speed ||= 1;
    my $hours = $distance / $speed;
    my $seconds = 60 * 60 * $hours;
    $seconds += 300;
#    $seconds = 1 if $seconds < 1;
    $seconds = 300 if $seconds < 300; #minimum time for flights
    return sprintf('%.0f', $seconds);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
