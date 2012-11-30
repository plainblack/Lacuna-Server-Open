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
    type                    => { data_type => 'varchar', size => 30, is_nullable => 0 }, # probe, colony_ship, spy_pod, cargo_ship, space_station, smuggler_ship, mining_platform_ship, terraforming_platform_ship, gas_giant_settlement_ship
    task                    => { data_type => 'varchar', size => 30, is_nullable => 0 }, # Docked, Building, Travelling, Mining, Defend, Orbiting
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
);
__PACKAGE__->typecast_map(type => {
    'probe'                                 => 'Lacuna::DB::Result::Ships::Probe',
    'stake'                                 => 'Lacuna::DB::Result::Ships::Stake',
    'supply_pod'                            => 'Lacuna::DB::Result::Ships::SupplyPod',
    'supply_pod2'                           => 'Lacuna::DB::Result::Ships::SupplyPod2',
    'supply_pod3'                           => 'Lacuna::DB::Result::Ships::SupplyPod3',
    'supply_pod4'                           => 'Lacuna::DB::Result::Ships::SupplyPod4',
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
    'fissure_healer'                        => 'Lacuna::DB::Result::Ships::FissureHealer',
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

sub max_occupants {
    my $self = shift;
    return 0 unless $self->pilotable;
    return int($self->hold_size / 350);
}

sub arrive {
    my $self = shift;
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
    my $self = shift;
    $self->note_arrival;
}

sub note_arrival {
    my $self = shift;
    Lacuna->cache->increment($self->type.'_arrive_'.$self->foreign_body_id.$self->foreign_star_id, $self->body->empire_id,1, 60*60*24*30);
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
    my $self = shift;
    $self->direction( ($self->direction eq 'out') ? 'in' : 'out' );
#    $self->date_available(DateTime->now->add_duration( $self->date_available - $self->date_started ));
    $self->fleet_speed(0);
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
    return $self;
}

sub finish_construction {
    my ($self) = @_;
    $self->body->empire->add_medal($self->type);
    $self->task('Docked');
    $self->date_available(DateTime->now);
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
    return sprintf('%.0f', $seconds);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
