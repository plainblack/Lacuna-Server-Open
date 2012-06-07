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
    builder => '_build_hostile_action',
);

sub _build_hostile_action { 0 }

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
    quantity                => { data_type => 'int', is_nullable => 0 },
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

foreach my $method (qw(insert update)) {
    around $method => sub {
        my $orig = shift;
        my $self = shift;

        # Recalculate the ship mark
        my $mark = '';
        for my $arg (qw(body_id shipyard_id date_started date_available type task name speed stealth
            combat hold_size roundtrip direction foreign_body_id foreign_star_id berth_level
            )) {
            $mark .= $self->$arg || '';
            $mark .= '#';
        }
        $mark .= encode_json $self->payload;
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

# Delete a quantity of ships from a fleet
sub delete_quantity {
    my ($self, $quantity) = @_;

    my $new_quantity = $self->quantity - $quantity;
    if ($new_quantity <= 0) {
        $self->delete;
    }
    else {
        $self->quantity($new_quantity);
        $self->update;
    }
    return $self;
}

# split some ships from a fleet to create a new fleet
sub split {
    my ($self, $quantity) = @_;

    # check that there are enough ships
    if ($quantity > $self->quantity) {
        return;
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

sub arrive {
    my ($self) = @_;
    eval {$self->handle_arrival_procedures}; # throws exceptions to stop subsequent actions from happening
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
    my ($self) = @_;
    $self->note_arrival;
}

sub note_arrival {
    my ($self) = @_;
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

sub can_recall {
    my ($self) = @_;
    unless ($self->task ~~ [qw(Defend Orbiting)]) {
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
    my ($self, $target) = @_;
    my %status = (
        id              => $self->id,
        quantity        => $self->quantity,
        name            => $self->name,
        mark            => $self->mark,
        type_human      => $self->type_formatted,
        type            => $self->type,
        task            => $self->task,
        speed           => $self->speed,
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
    );
    if ($target) {
        $status{estimated_travel_time} = $self->calculate_travel_time($target);
    }
    if ($self->task ~~ [qw(Travelling Defend Orbiting)]) {
        my $body = $self->body;
        my $from = {
            id      => $body->id,
            name    => $body->name,
            type    => 'body',
        };
        if ($self->task eq 'Travelling') {
            my $target = ($self->foreign_body_id) ? $self->foreign_body : $self->foreign_star;
            my $to = {
                id      => $target->id,
                name    => $target->name,
                type    => (ref $target eq 'Lacuna::DB::Result::Map::Star') ? 'star' : 'body',
            };
            if ($self->direction eq 'in') {
                my $temp = $from;
                $from = $to;
                $to = $temp;
            }
            $status{to}             = $to;
            $status{date_arrives}   = $status{date_available};
        }
        $status{from} = $from;
    }
    elsif ($self->task ~~ [qw(Defend Orbiting)]) {
        my $orbiting = {
            id      => $self->foreign_body_id,
            name    => $self->foreign_body->name,
            type    => 'body',
            x       => $self->foreign_body->x,
            y       => $self->foreign_body->y,
        };
        $status{orbiting} = $orbiting;
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
    $self->date_available(DateTime->now->add(seconds=>$self->calculate_travel_time($target)));
    $self->date_started(DateTime->now);
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
    $self->date_available($arrival);

    if ($options{target}->isa('Lacuna::DB::Result::Map::Body')) {
        $self->foreign_body_id($options{target}->id);
#        $self->foreign_body($options{target});
        $self->foreign_star_id(undef);
#        $self->foreign_star(undef);
    }
    elsif ($options{target}->isa('Lacuna::DB::Result::Map::Star')) {
        $self->foreign_star_id($options{target}->id);
#        $self->foreign_star($options{target});
        $self->foreign_body_id(undef);
#        $self->foreign_body(undef);
    }
    else {
        confess [1002, 'You cannot send a ship to a non-existant target.'];
    }
    $self->update;
    return $self;
}

sub finish_construction {
    my ($self) = @_;
    $self->body->empire->add_medal($self->type);
    $self->task('Docked');
    $self->date_available(DateTime->now);
    $self->shipyard_id(0);
    $self->update;
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
    $self->payload({});
    return $self;
}

# DISTANCE

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

