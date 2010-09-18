package Lacuna::DB::Result::Ships;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date to_seconds randint);
use DateTime;
use feature "switch";

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('ships');
__PACKAGE__->add_columns(
    spaceport_id            => { data_type => 'int', size => 11, is_nullable => 1 },
    shipyard_id             => { data_type => 'int', size => 11, is_nullable => 1 },
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    date_started            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    date_available          => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    type                    => { data_type => 'varchar', size => 30, is_nullable => 0 }, # probe, colony_ship, spy_pod, cargo_ship, space_station, smuggler_ship, mining_platform_ship, terraforming_platform_ship, gas_giant_settlement_platform_ship
    task                    => { data_type => 'varchar', size => 10, is_nullable => 0 }, # Docked, Building, Travelling, Mining
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    speed                   => { data_type => 'int', size => 11, is_nullable => 0 },
    stealth                 => { data_type => 'int', size => 11, is_nullable => 0 },
    hold_size               => { data_type => 'int', size => 11, is_nullable => 0 },
    payload                 => { data_type => 'mediumtext', is_nullable => 1, 'serializer_class' => 'JSON' },
    roundtrip               => { data_type => 'bit', default_value => 0 },
    direction               => { data_type => 'varchar', size => 3, is_nullable => 0 }, # in || out
    foreign_body_id         => { data_type => 'int', size => 11, is_nullable => 1 },
    foreign_star_id         => { data_type => 'int', size => 11, is_nullable => 1 },
);
__PACKAGE__->typecast_map(type => {
    'probe'                                 => 'Lacuna::DB::Result::Ships::Probe',
    'colony_ship'                           => 'Lacuna::DB::Result::Ships::ColonyShip',
    'spy_pod'                               => 'Lacuna::DB::Result::Ships::SpyPod',
    'cargo_ship'                            => 'Lacuna::DB::Result::Ships::CargoShip',
    'space_station'                         => 'Lacuna::DB::Result::Ships::SpaceStation',
    'smuggler_ship'                         => 'Lacuna::DB::Result::Ships::SmugglerShip',
    'mining_platform_ship'                  => 'Lacuna::DB::Result::Ships::MiningPlatformShip',
    'terraforming_platform_ship'            => 'Lacuna::DB::Result::Ships::TerraformingPlatformShip',
    'gas_giant_settlement_platform_ship'    => 'Lacuna::DB::Result::Ships::GasGiantSettlementPlatformShip',
    'scanner'                               => 'Lacuna::DB::Result::Ships::Scanner',
    'detonator'                             => 'Lacuna::DB::Result::Ships::Detonator',
    'excavator'                             => 'Lacuna::DB::Result::Ships::Excavator',
    'scow'                                  => 'Lacuna::DB::Result::Ships::Scow',
    'freighter'                             => 'Lacuna::DB::Result::Ships::Freighter',
    'dory'                                  => 'Lacuna::DB::Result::Ships::Dory',
    'bomber'                                => 'Lacuna::DB::Result::Ships::Bomber',
    'spy_shuttle'                           => 'Lacuna::DB::Result::Ships::SpyShuttle',
    'drone'                                 => 'Lacuna::DB::Result::Ships::Drone',
    'fighter'                               => 'Lacuna::DB::Result::Ships::Fighter',
    'observatory_seeker'                    => 'Lacuna::DB::Result::Ships::ObservatorySeeker',
    'spaceport_seeker'                      => 'Lacuna::DB::Result::Ships::SpacePortSeeker',
    'security_ministry_seeker'              => 'Lacuna::DB::Result::Ships::SecurityMinistrySeeker',
});

with 'Lacuna::Role::Container';

__PACKAGE__->belongs_to('spaceport', 'Lacuna::DB::Result::Building', 'spaceport_id');
__PACKAGE__->belongs_to('shipyard', 'Lacuna::DB::Result::Building', 'shipyard_id');
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');
__PACKAGE__->belongs_to('foreign_star', 'Lacuna::DB::Result::Map::Star', 'foreign_star_id');
__PACKAGE__->belongs_to('foreign_body', 'Lacuna::DB::Result::Map::Body', 'foreign_body_id');

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::University',  level => 1 };
use constant base_food_cost      => 1;
use constant base_water_cost     => 1;
use constant base_energy_cost    => 1;
use constant base_ore_cost       => 1;
use constant base_time_cost      => 1;
use constant base_waste_cost     => 1;
use constant base_speed     => 1;
use constant base_stealth   => 0;
use constant base_hold_size => 0;
use constant pilotable      => 0;

sub is_available {
    my ($self) = @_;
    return ($self->task eq 'Docked');
}

sub can_send_to_target {
    confess [1009, 'Cannot be used in that manner.'];
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
    my $self = shift;
    my %status = (
        id              => $self->id,
        name            => $self->name,
        type_human      => $self->type_formatted,
        type            => $self->type,
        task            => $self->task,
        speed           => $self->speed,
        stealth         => $self->stealth,
        hold_size       => $self->hold_size,
        date_started    => $self->date_started_formatted,
        date_available  => $self->date_available_formatted,
    );
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
    return to_seconds(DateTime->now - $self->date_available);
}

sub turn_around {
    my $self = shift;
    $self->direction( ($self->direction eq 'out') ? 'in' : 'out' );
    $self->date_available(DateTime->now->add_duration( $self->date_available - $self->date_started ));
    $self->date_started(DateTime->now);
    $self->update;
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
    $self->update;
}

sub land {
    my ($self) = @_;
    $self->task('Docked');
    $self->update;
}


sub arrive {
    confess 'override me';
}

sub capture_with_spies {
    my ($self) = @_;
    return 0 unless (exists $self->payload->{spies} || exists $self->payload->{fetch_spies} );
    my $body = $self->foreign_body;
    return 0 if ($body->empire_id == $self->body->empire_id);
    my $security = $body->get_building_of_class('Lacuna::DB::Result::Security');
    return 0 unless defined $security && $security->efficiency > 0;
    my $security_boost = ($security->level * 100) / $security->efficiency;
    $security_boost *= 100;
    return 0 unless (randint(1,10000) + $security_boost > $self->stealth);
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    foreach my $id ((@{$self->payload->{spies}}, @{$self->payload->{fetch_spies}})) {
        next unless $id;
        my $spy = $spies->find($id);
        next unless defined $spy;
        $spy->go_to_jail;
    }
    $self->delete;
    return 1;
}


sub pick_up_spies {
    my $self = shift;
    my $empire_id = $self->body->empire_id;
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    my @riding;
    foreach my $id (@{$self->payload->{fetch_spies}}) {
        my $spy = $spies->find($id);
        next unless defined $spy;
        next unless $spy->is_available;
        next unless $spy->empire_id eq $empire_id;
        push @riding, $spy->id;
        $spy->available_on($self->date_available);
        $spy->on_body_id($self->body_id);
        $spy->task('Travelling');
        $spy->started_assignment(DateTime->now),
        $spy->update;
    }
    my $payload = $self->payload;
    $payload->{spies} = \@riding;
    $self->payload($payload);
    $self->update;
}

sub handle_cargo_exchange {
    my $self = shift;
    if ($self->direction eq 'out') {
        $self->unload($self->payload, $self->foreign_body);
        $self->payload({});
        $self->turn_around;
        $self->pick_up_spies; # goes after turn around so we have the new date available
    }
    else {
        $self->unload($self->payload, $self->body);
        $self->payload({});
        $self->land;
    }
}

sub trigger_defense {
    my $self = shift;
    my $body_attacked = $self->foreign_body;
    my $defense = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        { body_id => $self->foreign_body_id, type => { in => [qw(drone fighter)]}},
        { rows => 1 }
        )->single;
    if (defined $defense) {
        $self->body->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'ship_shot_down.txt',
            params      => [$self->type_formatted, $body_attacked->name],
        );
        $body_attacked->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'we_shot_down_a_ship.txt',
            params      => [$self->type_formatted, $body_attacked->name, $self->body->empire_id, $self->body->empire->name],
        );
        $body_attacked->add_news(20, sprintf('An amateur astronomer witnessed an explosion in the sky today over %s.',$body_attacked->name));
        $self->delete;
        if ($defense->type eq 'fighter' && randint(1,100) > 50) {
            # fighter lives
        }
        else {
            $defense->delete;
        }
        return 1;
    }
    return 0;
}

sub damage_building {
    my ($self, $building) = @_;
    my $body_attacked = $self->foreign_body;
    $building ||= Lacuna->db->resultset('Lacuna::DB::Result::Building')->search(
        { body_id => $self->foreign_body_id },
        {order_by => { -desc => 'efficiency'}, rows=>1}
        )->single;
    $building->body($body_attacked);
    $building->spend_efficiency(randint(1,10));
    $building->update;
    $self->body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'our_ship_hit_building.txt',
        params      => [$self->type_formatted, $body_attacked->name, $building->name],
    );
    $body_attacked->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_hit_building.txt',
        params      => [$self->type_formatted, $body_attacked->name, $self->body->empire->name],
    );
    $body_attacked->add_news(70, sprintf('An attack ship screamed out of the sky and damaged the %s on %s.',$building->name, $body_attacked->name));
    $self->delete;
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
