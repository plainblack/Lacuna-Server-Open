package Lacuna::DB::Result::Fleet;

use Moose;
use utf8;
#no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date randint);
use DateTime;
use Digest::MD4 qw(md4_hex);
use JSON;

use feature "switch";

has 'hostile_action' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,
);

# Fleet has that quantity of ships, or fractional
# e.g. if fleet has 3.1 ships, quantity can be any of
# 1,2,3,0.1,1.1,2.1,3.1, but nothing else.
#
sub has_that_quantity {
    my ($self, $qty) = @_;
    if ($qty > $self->quantity) {
        confess [1009, "You don't have that many ships in the fleet"];
    }
    my $fleet_frac  = (($self->quantity * 10) % 10) / 10;
    my $req_frac    = (($qty * 10) % 10) / 10;
    if ($req_frac > 0 and $req_frac != $fleet_frac) {
        confess [1009, "You must specify either whole numbers, or the fractional part of the fleet"];
    }
}

# Fleet has that (integer) quantity of ships
#
sub has_that_quantity_int {
    my ($self, $qty) = @_;

    if (not defined $qty or $qty < 0 or int($qty) != $qty) {
        confess [1009, 'Quantity must be a positive integer'];
    }
    if ($qty > $self->quantity) {
        confess [1009, "You don't have that many ships in the fleet"];
    }
    return 1;                              
}

sub can_recall {
    my ($self) = @_;
    
    if ($self->task ~~ [qw(Defend Orbiting)]) {
        return 1;
    }
    confess [1010, 'That fleet is busy.'];
}

sub can_scuttle {
    my ($self) = @_;

    if ($self->task eq 'Docked') {
        return 1;
    }
    confess [1010, 'That fleet is busy.'];
}

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('fleet');
__PACKAGE__->add_columns(
    body_id                 => { data_type => 'int', is_nullable => 0 },
    mark                    => { data_type => 'varchar', size => 10, is_nullable => 0 },
    shipyard_id             => { data_type => 'int', is_nullable => 0 },
    date_started            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    date_available          => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    type                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    task                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
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
    berth_level             => { data_type => 'int', is_nullable => 0 },
    quantity                => { data_type => 'float', size => [11,1], is_nullable => 0}
);
__PACKAGE__->typecast_map(type => {
    'probe'                         => 'Lacuna::DB::Result::Fleet::Probe',
    'stake'                         => 'Lacuna::DB::Result::Fleet::Stake',
    'supply_pod'                    => 'Lacuna::DB::Result::Fleet::SupplyPod',
    'supply_pod2'                   => 'Lacuna::DB::Result::Fleet::SupplyPod2',
    'supply_pod3'                   => 'Lacuna::DB::Result::Fleet::SupplyPod3',
    'supply_pod4'                   => 'Lacuna::DB::Result::Fleet::SupplyPod4',
    'placebo'                       => 'Lacuna::DB::Result::Fleet::Placebo',
    'placebo2'                      => 'Lacuna::DB::Result::Fleet::Placebo2',
    'placebo3'                      => 'Lacuna::DB::Result::Fleet::Placebo3',
    'placebo4'                      => 'Lacuna::DB::Result::Fleet::Placebo4',
    'placebo5'                      => 'Lacuna::DB::Result::Fleet::Placebo5',
    'placebo6'                      => 'Lacuna::DB::Result::Fleet::Placebo6',
    'short_range_colony_ship'       => 'Lacuna::DB::Result::Fleet::ShortRangeColonyShip',
    'colony_ship'                   => 'Lacuna::DB::Result::Fleet::ColonyShip',
    'spy_pod'                       => 'Lacuna::DB::Result::Fleet::SpyPod',
    'cargo_ship'                    => 'Lacuna::DB::Result::Fleet::CargoShip',
    'space_station'                 => 'Lacuna::DB::Result::Fleet::SpaceStation',
    'smuggler_ship'                 => 'Lacuna::DB::Result::Fleet::SmugglerShip',
    'mining_platform_ship'          => 'Lacuna::DB::Result::Fleet::MiningPlatformShip',
    'terraforming_platform_ship'    => 'Lacuna::DB::Result::Fleet::TerraformingPlatformShip',
    'gas_giant_settlement_ship'     => 'Lacuna::DB::Result::Fleet::GasGiantSettlementPlatformShip',
    'scanner'                       => 'Lacuna::DB::Result::Fleet::Scanner',
    'surveyor'                      => 'Lacuna::DB::Result::Fleet::Surveyor',
    'detonator'                     => 'Lacuna::DB::Result::Fleet::Detonator',
    'excavator'                     => 'Lacuna::DB::Result::Fleet::Excavator',
    'scow'                          => 'Lacuna::DB::Result::Fleet::Scow',
    'scow_large'                    => 'Lacuna::DB::Result::Fleet::ScowLarge',
    'scow_mega'                     => 'Lacuna::DB::Result::Fleet::ScowMega',
    'scow_fast'                     => 'Lacuna::DB::Result::Fleet::ScowFast',
    'freighter'                     => 'Lacuna::DB::Result::Fleet::Freighter',
    'dory'                          => 'Lacuna::DB::Result::Fleet::Dory',
    'barge'                         => 'Lacuna::DB::Result::Fleet::Barge',
    'galleon'                       => 'Lacuna::DB::Result::Fleet::Galleon',
    'hulk'                          => 'Lacuna::DB::Result::Fleet::Hulk',
    'hulk_huge'                     => 'Lacuna::DB::Result::Fleet::HulkHuge',
    'hulk_fast'                     => 'Lacuna::DB::Result::Fleet::HulkFast',
    'snark'                         => 'Lacuna::DB::Result::Fleet::Snark',
    'snark2'                        => 'Lacuna::DB::Result::Fleet::Snark2',
    'snark3'                        => 'Lacuna::DB::Result::Fleet::Snark3',
    'spy_shuttle'                   => 'Lacuna::DB::Result::Fleet::SpyShuttle',
    'drone'                         => 'Lacuna::DB::Result::Fleet::Drone',
    'fighter'                       => 'Lacuna::DB::Result::Fleet::Fighter',
    'sweeper'                       => 'Lacuna::DB::Result::Fleet::Sweeper',
    'bleeder'                       => 'Lacuna::DB::Result::Fleet::Bleeder',
    'thud'                          => 'Lacuna::DB::Result::Fleet::Thud',
    'observatory_seeker'            => 'Lacuna::DB::Result::Fleet::ObservatorySeeker',
    'spaceport_seeker'              => 'Lacuna::DB::Result::Fleet::SpacePortSeeker',
    'security_ministry_seeker'      => 'Lacuna::DB::Result::Fleet::SecurityMinistrySeeker',
});

with 'Lacuna::Role::Container';

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');
__PACKAGE__->belongs_to('foreign_star', 'Lacuna::DB::Result::Map::Star', 'foreign_star_id');
__PACKAGE__->belongs_to('foreign_body', 'Lacuna::DB::Result::Map::Body', 'foreign_body_id');

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

# It's a little dangerous modifying data in the insert and update
# methods since it is akin to 'modifying data at a distance',
# however, the other option is to ensure that everywhere that 
# does an insert or update handles it correctly, which is even more
# dangerous and error prone.
#
foreach my $method (qw(insert update)) {
    around $method => sub {
        my $orig = shift;
        my $self = shift;

        # over-ride the dates if Docked so we can have common 'mark's
        if ($self->task eq "Docked") {
            $self->date_started("2000-01-01 00:00:00");
            $self->date_available("2000-01-01 00:00:00");
        }
        # Recalculate the ship mark
        my $mark = '';
        for my $arg (qw(body_id shipyard_id date_started date_available type task name speed stealth
            combat hold_size roundtrip direction foreign_body_id foreign_star_id berth_level
            )) {
            $mark .= $self->$arg || '';
            $mark .= '#';
        }
        $mark .= $self->payload ? encode_json($self->payload) : '{}';
 
        $mark = md4_hex($mark);
        $self->mark(substr $mark,0,10);
        if ($method eq 'update') {
            # For an update, see if there is another fleet with the same mark
            
            my ($other_fleet) = $self->result_source->resultset->search({
                mark    => $self->mark,
                id      => {'!=' => $self->id},
            });
            if ($other_fleet) {
                # Merge the other fleet into this one
                $self->quantity($self->quantity + $other_fleet->quantity);
                $other_fleet->delete;
            }

        }
        # we don't merge on an insert, this is to allow us to 'clone' an existing fleet
        # and only merge it later when the new clone is updated

        return $self->$orig(@_);
    };
}

# Schedule a future call to handle a fleet action
#
sub schedule {
    my ($self, $args) = @_;

    my $schedule = Lacuna->db->resultset('Schedule')->create({
        queue       => 'fleet',
        delivery    => $args->{delivery},
        priority    => $args->{priority} ? $args->{priority} : 0,
        parent_table=> 'fleet',
        row_id      => $self->id,
        task        => $args->{task},
        args        => $args->{args} ? $args->{args} : {},
    });
    return $schedule;    
}


# Return the total combat strength of the fleet
#
sub fleet_combat {
    my ($self) = @_;

    return $self->combat * $self->quantity;
}

# In a battle, if the fleet_combat is reduced, then the number of
# ships is adjusted accordingly
#   returns undef if destroyed utterly
#   
sub survives_damage {
    my ($self, $damage) = @_;

    my $ships_lost = $damage / $self->combat;
    if ($self->delete_quantity($ships_lost)) {
        # then some ships remain in the fleet
        return $self;
    }
    # the fleet was destroyed
}


# Delete a quantity of ships from a fleet
# We allow 'tenths' of a ship but always round down.
# Returns undef if we remove more ships than are in the fleet
# and it deletes the fleet
#
sub delete_quantity {
    my ($self, $quantity) = @_;

    my $new_quantity = $self->quantity - $quantity;
    if ($new_quantity < 0.1) {
        $self->delete;
        return;
    }
    $new_quantity = int($new_quantity * 10) / 10;
    $self->quantity($new_quantity);
    $self->update;
    return $self;
}

# split some ships from a fleet to create a new fleet
sub split {
    my ($self, $quantity) = @_;

    # check that there are enough ships
    if ($quantity > $self->quantity) {
        return;
    }    
    if ($quantity == $self->quantity) {
        return $self;
    }
    # update the original fleet with the reduced quantity
    $self->quantity($self->quantity - $quantity);
    $self->update;
    
    # create a new fleet (note insert does not automatically merge)
    my $args;
    for my $arg (qw(mark body_id shipyard_id date_started date_available type task name speed stealth
        combat hold_size payload roundtrip direction foreign_body_id foreign_star_id berth_level
        )) {
        $args->{$arg} = $self->$arg;
    }
    $args->{quantity} = $quantity;
    $args->{shipyard_id} = 0;
    my $fleet = $self->result_source->resultset->create($args);
    return $fleet;
}

sub max_occupants {
    my ($self) = @_;
    return 0 unless $self->pilotable;
    return int($self->hold_size / 350);
}

before delete => sub {
    my ($self) = @_;

    # delete any arrival or finish_construction jobs
    #
    my $schedule_rs = Lacuna->db->resultset('Schedule')->search({
        parent_table    => 'Fleet',
        parent_id       => $self->id,
    });
    while (my $schedule = $schedule_rs->next) {
        $schedule->delete;
    }
};

before task => sub {
    my ($self, $arg) = @_;

    if ( $arg && $self->task ) {
        # to be safe, if a ship changes *from* either 'Travelling' or 'Building' we
        # delete any Schedule (and hence any beanstalk job) for it.
        #
        if (($self->task eq 'Travelling' or $self->task eq 'Building') and $arg ne $self->task) {
            # Then we need to delete the 'schedule' and beanstalk job
            my $schedule_rs = Lacuna->db->resultset('Schedule')->search({
                parent_table    => 'Fleet',
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

# Change the date_available of the fleet
sub re_schedule {
    my ($self, $date_available) = @_;

    my $schedule_rs = Lacuna->db->resultset('Schedule')->search({
        parent_table    => 'Fleet',
        parent_id       => $self->id,
    });
    while (my $schedule = $schedule_rs->next) {
        my $new_schedule = Lacuna->db->resultset('Schedule')->create({
            parent_table    => 'Fleet',
            queue           => $schedule->queue,
            parent_id       => $self->id,
            task            => $schedule->task,
            delivery        => $date_available,
        });
        $schedule->delete;
    }
}

sub arrive {
    my ($self) = @_;

    my ($schedule) = Lacuna->db->resultset('Schedule')->search({
        parent_table    => 'Fleet',
        parent_id       => $self->id,
        task            => 'arrive',
    });
    $schedule->delete if defined $schedule;

    if ($self->task eq 'Travelling') {
        eval {
            # throws exceptions to stop subsequent actions from happening
            $self->handle_arrival_procedures
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
            $self->turn_around;
        }
        else {
            $self->land;
        }
        $self->update;
    }
}

sub handle_arrival_procedures {
    my ($self) = @_;
    $self->note_arrival;
}

sub note_arrival {
    my ($self) = @_;
    no warnings 'uninitialized';
    Lacuna->cache->increment($self->type.'_arrive_'.$self->foreign_body_id.$self->foreign_star_id, $self->body->empire_id,1, 60*60*24*30);
}

sub is_available {
    my ($self) = @_;
    return ($self->task eq 'Docked');
}

sub can_send_to_target {
    my ($self) = @_;
    if ($self->task ne 'Docked') {
        confess [1010, 'That fleet is busy.'];
    }
    return 1;
}

sub type_formatted {
    my ($self) = @_;

    return $self->type_human($self->type);
}

sub type_human {
    my ($self, $type) = @_;

    $type =~ s/_/ /g;
    $type =~ s/\b(\w)/\u$1/g;
    return $type;
}

sub date_started_formatted {
    my ($self) = @_;
    return format_date($self->date_started);
}

sub date_available_formatted {
    my ($self) = @_;
    return format_date($self->date_available);
}

sub get_status {
    my ($self, $target, $args) = @_;

    my %status = (
        id              => $self->id,
        quantity        => $self->quantity,
        task            => $self->task,
    );

    my $date_available = $self->date_available_formatted;
    # show details block if it is from own or allied fleet
    # or the fleet_details_level is high enough
    if ( not defined $args
        or ($self->body->empire_id ~~ $args->{ally_ids} ) 
        or ($args->{fleet_details_level} and $args->{fleet_details_level} >= $self->stealth)) {    
        $status{details} = {
            name            => $self->name,
            mark            => $self->mark,
            type_human      => $self->type_formatted,
            type            => $self->type,
            speed           => $self->speed,
            stealth         => $self->stealth,
            combat          => $self->combat,
            hold_size       => $self->hold_size,
            berth_level     => $self->berth_level,
            date_started    => $self->date_started_formatted,
            date_available  => $date_available,
            max_occupants   => $self->max_occupants,
            payload         => $self->format_description_of_payload,
            can_scuttle     => eval {$self->can_scuttle} ? 1 : 0,
            can_recall      => eval {$self->can_recall} ? 1 : 0,
        };
    }
    
    if ($target) {
        $status{estimated_travel_time} = $self->calculate_travel_time($target);
    }
    if ($self->task ~~ [qw(Travelling Defend Orbiting)]) {
        my $body = $self->body;
        my $from = {};

        # only show 'from' block if the stealth is low enough
        #
        if ( not defined $args
            or ($self->body->empire_id ~~ $args->{ally_ids} ) 
            or ($args->{fleet_from_level} and $args->{fleet_from_level} >= $self->stealth)) {    
            $from = {
                id      => $body->id,
                name    => $body->name,
                type    => 'body',
                owner   => 'Foreign',
                empire  => {
                    id      => $body->empire_id,
                    name    => $body->empire->name,
                }
            };
        }
        my $target = ($self->foreign_body_id) ? $self->foreign_body : $self->foreign_star;

        my $to = {
            id      => $target->id,
            name    => $target->name,
            type    => (ref $target eq 'Lacuna::DB::Result::Map::Star') ? 'star' : 'body',
            x       => $target->x,
            y       => $target->y,
        };

        if ($self->task eq 'Travelling') {
            if ($self->direction eq 'in') {
                my $temp = $from;
                $from = $to;
                $to = $temp;
            }
            $status{date_arrives} = $date_available;
        }
        $status{from}   = $from;
        $status{to}     = $to;
    }
    return \%status;
}

sub seconds_remaining {
    my ($self) = @_;
    return time - $self->date_available->epoch;
}

sub turn_around {
    my ($self) = @_;

    $self->direction( ($self->direction eq 'out') ? 'in' : 'out' );
    my $target = ($self->foreign_body_id) ? $self->foreign_body : $self->foreign_star;
    my $arrival = DateTime->now->add(seconds => $self->calculate_travel_time($target));
    $self->date_available($arrival);
    $self->date_started(DateTime->now);

    my $schedule = Lacuna->db->resultset('Schedule')->create({
        parent_table    => 'Fleet',
        queue           => 'reboot-arrive',
        parent_id       => $self->id,
        task            => 'arrive',
        delivery        => $arrival,
    });

    return $self;
}

sub recall {
    my ($self) = @_;
    
    # The time to get back is the same as the time to get here.
    # TODO (we could allow return to be a full fleet speed, but I can't be bothered
    # to work out how to do that yet)

    my $now = DateTime->now;
    my $duration = $now - $self->date_started;
    my $options = {
        payload     => $self->payload,
        arrival     => $now + $duration,
        direction   => 'in',
        target      => $self->body,
    };
    $self->send(%$options);
}

sub send {
    my ($self, %options ) = @_;

    $self->date_started(DateTime->now);
    $self->task('Travelling');
    $self->payload($options{payload} || {});
    $self->roundtrip($options{roundtrip} || 0);
    $self->direction($options{direction} || 'out');
    my $arrival = $options{arrival} || DateTime->now->add(seconds=>$self->calculate_travel_time($options{target}));
    $self->date_available($arrival);

    if ($options{target}->isa('Lacuna::DB::Result::Map::Body')) {
        $self->foreign_body_id($options{target}->id);
        $self->foreign_star_id(undef);
    }
    elsif ($options{target}->isa('Lacuna::DB::Result::Map::Star')) {
        $self->foreign_star_id($options{target}->id);
        $self->foreign_body_id(undef);
    }
    else {
        confess [1002, 'You cannot send a ship to a non-existant target.'];
    }
    $self->update;
    my $schedule = Lacuna->db->resultset('Schedule')->create({
        delivery        => $arrival,
        queue           => 'reboot-arrive',
        parent_table    => 'Fleet',
        parent_id       => $self->id,
        task            => 'arrive',
    });

    return $self;
}

sub start_construction {
    my ($self) = @_;

    my $schedule = Lacuna->db->resultset('Schedule')->create({
        delivery        => $self->date_available,
        parent_table    => 'Fleet',
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
    $self->shipyard_id(0);
    $self->update;

    my ($schedule) = Lacuna->db->resultset('Schedule')->search({
        parent_table    => 'Fleet',
        parent_id       => $self->id,
        task            => 'finish_construction',
    });
    $schedule->delete if defined $schedule;

    return $self;
}

# Remove one fleet from the build queue, reschedule all other following fleet
#
sub reschedule_queue {
    my ($self) = @_;

    my $start_time = DateTime->now;
    my $fleet_end_time;         # when the current fleet completes
    my $building_time;          # The end time of the building working

    my @fleets_queue = Lacuna->db->resultset('Fleet')->search({
        task        => 'Building',
        shipyard_id => $self->shipyard_id,
    },{
        order_by    => { -asc => 'date_available'},
    })->all;

    my $fleet;
    $building_time = DateTime->now;
    BUILD:
    while ($fleet = shift @fleets_queue) {
        $fleet_end_time = $fleet->date_available;
        if ($fleet->id == $self->id) {
            last BUILD;
        }
        # Start time of the next ship is the end time of this one
        $start_time = $fleet_end_time;
    }
    if ($fleet) {
        # Remove this scheduled event
        my $duration = $fleet_end_time->epoch - $start_time->epoch;
        # Don't bother to reschedule if it is a small period
        if ($duration > 5) {
            my ($schedule) = Lacuna->db->resultset('Schedule')->search({
                parent_table    => 'Fleet',
                parent_id       => $self->id,
                task            => 'finish_construction',
            });
            $schedule->delete if defined $schedule;
            $building_time = $start_time;

            # Change the scheduled time for all subsequent builds (if any)
            while (my $fleet = shift @fleets_queue) {
                my $construction_ends = $fleet->date_available->clone->subtract(seconds => $duration);
                $building_time = $construction_ends;

                $fleet->date_available($construction_ends);
                $fleet->update;
                Lacuna->db->resultset('Schedule')->reschedule({
                    parent_table    => 'Fleet',
                    parent_id       => $fleet->id,
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
    $self->date_available(DateTime->now);
    $self->foreign_body_id(undef);
    $self->foreign_star_id(undef);
    $self->payload({});
    return $self;
}

# DISTANCE
sub earliest_arrival {
    my ($self, $target) = @_;

    my $now = DateTime->now->add(seconds=>$self->calculate_travel_time($target));
}

sub calculate_travel_time {
    my ($self, $target) = @_;

    my $distance = $self->body->calculate_distance_to_target($target);
    my $speed = $self->speed;
    return $self->travel_time($self->body, $target, $speed);
}

sub travel_time {
    my ($class, $from, $target, $speed) = @_;

    my $distance = $from->calculate_distance_to_target($target);
    $speed ||= 1;
    my $hours = $distance / $speed;
    my $seconds = 60 * 60 * $hours;
    return sprintf('%.0f', $seconds);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

