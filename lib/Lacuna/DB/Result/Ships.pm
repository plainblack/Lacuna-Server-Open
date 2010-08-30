package Lacuna::DB::Result::Ships;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date to_seconds randint);
use DateTime;
use feature "switch";

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
    hold_size               => { data_type => 'int', size => 11, is_nullable => 0 },
    payload                 => { data_type => 'mediumtext', is_nullable => 1, 'serializer_class' => 'JSON' },
    roundtrip               => { data_type => 'bit', default_value => 0 },
    direction               => { data_type => 'varchar', size => 3, is_nullable => 0 }, # in || out
    foreign_body_id         => { data_type => 'int', size => 11, is_nullable => 1 },
    foreign_star_id         => { data_type => 'int', size => 11, is_nullable => 1 },
);

with 'Lacuna::Role::Container';

__PACKAGE__->belongs_to('spaceport', 'Lacuna::DB::Result::Building', 'spaceport_id');
__PACKAGE__->belongs_to('shipyard', 'Lacuna::DB::Result::Building', 'shipyard_id');
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');
__PACKAGE__->belongs_to('foreign_star', 'Lacuna::DB::Result::Map::Star', 'foreign_star_id');
__PACKAGE__->belongs_to('foreign_body', 'Lacuna::DB::Result::Map::Body', 'foreign_body_id');

sub is_available {
    my ($self) = @_;
    return ($self->task eq 'Docked');
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
        stealth         => 0,
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
    $self->task('Docked');
    $self->update;
}

sub land {
    my ($self) = @_;
    $self->task('Docked');
    $self->update;
}

sub arrive {
    my ($self) = @_;
    given ($self->type) { # wouldn't have to do this if we subclassed ships, but oh well
        when ('probe') { $self->arrive_probe }
        when ('spy_pod') { $self->arrive_spy_pod }
        when ('cargo_ship') { $self->arrive_cargo_ship }
        when ('terraforming_platform_ship') { $self->arrive_terraforming_platform_ship }
        when ('gas_giant_settlement_platform_ship') { $self->arrive_gas_giant_settlement_platform_ship }
        when ('mining_platform_ship') { $self->arrive_mining_platform_ship }
        when ('colony_ship') { $self->arrive_colony_ship }
        when ('smuggler_ship') { $self->arrive_smuggler_ship }
        when ('space_station') { $self->arrive_space_station }
    }
}

sub arrive_probe {
    my ($self) = @_;
    my $empire = $self->body->empire;
    $empire->add_probe($self->foreign_star_id, $self->body_id);
    $self->delete;
}
    
sub arrive_spy_pod {
    my ($self) = @_;
    $self->delete;
}
    
sub arrive_colony_ship {
    my ($self) = @_;
    my $empire = $self->body->empire;
    if ($self->direction eq 'out') {
        my $planet = $self->foreign_body;
        if ($planet->is_locked || $planet->empire_id) {
            $self->turn_around;
            $empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'cannot_colonize.txt',
                params      => [$planet->name, $planet->name],
            );
        }
        else {
            $planet->lock;
            $planet->found_colony($empire);
            $empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'colony_founded.txt',
                params      => [$planet->name, $planet->name],
            );
            $empire->is_isolationist(0);
            $empire->update;
            $self->delete;
        }
    }
    else {
        $self->land;
    }
}
    
sub arrive_terraforming_platform_ship {
    my ($self) = @_;
    if ($self->direction eq 'out') {
        my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::TerraformingLab');
        if (defined $lab) {
            $self->foreign_body->add_plan('Lacuna::DB::Result::Building::Permanent::TerraformingPlatform', 1, $lab->level);
        }
    }
    else {
        $self->land;
    }
}
    
sub arrive_gas_giant_settlement_platform_ship {
    my ($self) = @_;
    if ($self->direction eq 'out') {
        my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::GasGiantLab');
        if (defined $lab) {
            $self->foreign_body->add_plan('Lacuna::DB::Result::Building::Permanent::GasGiantPlatform', 1, $lab->level);
        }
    }
    else {
        $self->land;
    }
}
    
sub arrive_mining_platform_ship {
    my ($self) = @_;
    if ($self->direction eq 'out') {
        my $body = $self->body;
        my $ministry = $body->mining_ministry;
	unless (defined $ministry) {
            $self->turn_around;
        }
        my $empire = $body->empire;
        my $can = eval{$ministry->can_add_platform($self->foreign_body)};
        if ($can && !$@) {
            $ministry->add_platform($self->foreign_body)->update;
            $empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'mining_platform_deployed.txt',
                params      => [$self->foreign_body->name, $self->name],
            );
            $self->delete;
            my $type = $self->foreign_body;
            $type =~ s/^Lacuna::DB::Result::Map::Body::Asteroid::(\w+)$/$1/;
            $empire->add_medal($type);        }
        else {
            $self->turn_around;
            $empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'cannot_deploy_mining_platform.txt',
                params      => [$@->[1], $body->name, $self->name],
            );
        }
    }
    else {
        $self->land;
    }
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

sub capture_with_spies {
    my ($self, $multiplier) = @_;
    my $body = $self->foreign_body;
    return 0 if ($body->empire_id == $self->body->empire_id);
    my $security = $body->get_building_of_class('Lacuna::DB::Result::Security');
    return 0 unless defined $security;
    return 0 unless (randint(1,100) < $security->level * $multiplier);
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    my $sentence = DateTime->now->add(days => 30);
    foreach my $id ((@{$self->payload->{spies}}, @{$self->payload->{fetch_spies}})) {
        next unless $id;
        my $spy = $spies->find($id);
        next unless defined $spy;
        $spy->go_to_jail;
    }
    $self->delete;
}
    
sub arrive_cargo_ship {
    my ($self) = @_;
    my $captured = $self->capture_with_spies(2) if (exists $self->payload->{spies} || exists $self->payload->{fetch_spies} );
    unless ($captured) {
        $self->handle_cargo_exchange;
    }
}
    
sub arrive_smuggler_ship {
    my ($self) = @_;
    my $captured = $self->capture_with_spies(1) if (exists $self->payload->{spies} || exists $self->payload->{fetch_spies} );
    unless ($captured) {
        $self->handle_cargo_exchange;
    }
}
    
sub arrive_space_station {
    my ($self) = @_;
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
