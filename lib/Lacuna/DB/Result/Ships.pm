package Lacuna::DB::Result::Ships;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date randint);
use DateTime;
use feature "switch";

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('ships');
__PACKAGE__->add_columns(
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    shipyard_id             => { data_type => 'int', size => 11, is_nullable => 0 },
    date_started            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    date_available          => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    type                    => { data_type => 'varchar', size => 30, is_nullable => 0 }, # probe, colony_ship, spy_pod, cargo_ship, space_station, smuggler_ship, mining_platform_ship, terraforming_platform_ship, gas_giant_settlement_ship
    task                    => { data_type => 'varchar', size => 30, is_nullable => 0 }, # Docked, Building, Travelling, Mining
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    speed                   => { data_type => 'int', size => 11, is_nullable => 0 },
    stealth                 => { data_type => 'int', size => 11, is_nullable => 0 },
    combat                  => { data_type => 'int', size => 11, is_nullable => 0 },
    hold_size               => { data_type => 'int', size => 11, is_nullable => 0 },
    payload                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
    roundtrip               => { data_type => 'bit', default_value => 0 },
    direction               => { data_type => 'varchar', size => 3, is_nullable => 0 }, # in || out
    foreign_body_id         => { data_type => 'int', size => 11, is_nullable => 1 },
    foreign_star_id         => { data_type => 'int', size => 11, is_nullable => 1 },
);
__PACKAGE__->typecast_map(type => {
    'probe'                                 => 'Lacuna::DB::Result::Ships::Probe',
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
    'detonator'                             => 'Lacuna::DB::Result::Ships::Detonator',
    'excavator'                             => 'Lacuna::DB::Result::Ships::Excavator',
    'scow'                                  => 'Lacuna::DB::Result::Ships::Scow',
    'freighter'                             => 'Lacuna::DB::Result::Ships::Freighter',
    'dory'                                  => 'Lacuna::DB::Result::Ships::Dory',
    'snark'                                 => 'Lacuna::DB::Result::Ships::Snark',
    'spy_shuttle'                           => 'Lacuna::DB::Result::Ships::SpyShuttle',
    'drone'                                 => 'Lacuna::DB::Result::Ships::Drone',
    'fighter'                               => 'Lacuna::DB::Result::Ships::Fighter',
    'observatory_seeker'                    => 'Lacuna::DB::Result::Ships::ObservatorySeeker',
    'spaceport_seeker'                      => 'Lacuna::DB::Result::Ships::SpacePortSeeker',
    'security_ministry_seeker'              => 'Lacuna::DB::Result::Ships::SecurityMinistrySeeker',
});

with 'Lacuna::Role::Container';

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');
__PACKAGE__->belongs_to('foreign_star', 'Lacuna::DB::Result::Map::Star', 'foreign_star_id');
__PACKAGE__->belongs_to('foreign_body', 'Lacuna::DB::Result::Map::Body', 'foreign_body_id');

use constant prereq                 => { class=> 'Lacuna::DB::Result::Building::University',  level => 1 };
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
use constant pilotable              => 0;
use constant target_building        => undef;
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
    if (ref $@ eq 'ARRAY' && $@->[0] eq -1) {
        # this is an expected exception, it means one of the roles took over
        return;
    }
    elsif ($@) {
        # this is unexpected, so let's rethrow
        confess $@;
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

sub type_formatted {
    my $self = shift;
    my $type = $self->type;
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
        stealth         => $self->stealth,
        combat          => $self->combat,
        hold_size       => $self->hold_size,
        date_started    => $self->date_started_formatted,
        date_available  => $self->date_available_formatted,
        max_occupants   => $self->max_occupants,
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
    return \%status;
}

sub seconds_remaining {
    my $self = shift;
    return time - $self->date_available->epoch;
}

sub turn_around {
    my $self = shift;
    $self->direction( ($self->direction eq 'out') ? 'in' : 'out' );
    $self->date_available(DateTime->now->add_duration( $self->date_available - $self->date_started ));
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
    $self->date_available(DateTime->now->add(seconds=>$self->calculate_travel_time($options{target})));
    if ($options{target}->isa('Lacuna::DB::Result::Map::Body')) {
        $self->foreign_body_id($options{target}->id);
        $self->foreign_body($options{target});
    }
    elsif ($options{target}->isa('Lacuna::DB::Result::Map::Star')) {
        $self->foreign_star_id($options{target}->id);
        $self->foreign_star($options{target});
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

sub land {
    my ($self) = @_;
    $self->task('Docked');
    $self->payload({});
}




# DISTANCE



sub calculate_travel_time {
    my ($self, $target) = @_;
    my $distance = $self->body->calculate_distance_to_target($target);
    my $hours = $distance / $self->speed;
    my $seconds = 60 * 60 * $hours;
    return sprintf('%.0f', $seconds);
}



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
