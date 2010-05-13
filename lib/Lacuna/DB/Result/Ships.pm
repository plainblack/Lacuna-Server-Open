package Lacuna::DB::Result::Ships;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date to_seconds);
use DateTime;

__PACKAGE__->table('ship_builds');
__PACKAGE__->add_columns(
    spaceport_id            => { data_type => 'int', size => 11, is_nullable => 1 },
    shipyard_id             => { data_type => 'int', size => 11, is_nullable => 1 },
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    date_started            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    date_available          => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    type                    => { data_type => 'char', size => 30, is_nullable => 0 }, # probe, colony_ship, spy_pod, cargo_ship, space_station, smuggler_ship, mining_platform_ship, terraforming_platform_ship, gas_giant_settlement_platform_ship
    task                    => { data_type => 'char', size => 10, is_nullable => 0 }, # Docked, Building, Travelling, Mining
    name                    => { data_type => 'char', size => 30, is_nullable => 0 },
    speed                   => { data_type => 'int', size => 11, is_nullable => 0 },
    hold_size               => { data_type => 'int', size => 11, is_nullable => 0 },
    payload                 => { data_type => 'mediumtext', is_nullable => 1, 'serializer_class' => 'JSON' },
    roundtrip               => { data_type => 'int', size => 1, default_value => 0 },
    direction               => { data_type => 'char', size => 3, is_nullable => 0 }, # in || out
    foreign_body_id         => { data_type => 'int', size => 11, is_nullable => 1 },
    foreign_star_id         => { data_type => 'int', size => 11, is_nullable => 1 },
);

__PACKAGE__->belongs_to('spaceport', 'Lacuna::DB::Result::Building', 'spaceport_id', {join_type => 'left', cascade_delete => 0});
__PACKAGE__->belongs_to('shipyard', 'Lacuna::DB::Result::Building', 'shipyard_id', {join_type => 'left', cascade_delete => 0});
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');
__PACKAGE__->belongs_to('foreign_star', 'Lacuna::DB::Result::Map::Star', 'foreign_star_id');
__PACKAGE__->belongs_to('foreign_body', 'Lacuna::DB::Result::Map::Body', 'foreign_body_id');

sub date_started_formatted {
    my $self = shift;
    return format_date($self->date_started);
}

sub date_available_formatted {
    my $self = shift;
    return format_date($self->date_available);
}

sub seconds_remaining {
    my $self = shift;
    return to_seconds(DateTime->now - $self->date_available);
}

sub turn_around {
    my $self = shift;
    $self->direction( ($self->direction eq 'out') ? 'in' : 'out' );
    $self->date_available->add_duration( $self->date_available - $self->date_started );
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
    my $port = $self->body->spaceport->find_open_dock;
    return undef unless defined $port; # it stays in the queue until there's room
    $port->number_of_ships($port->number_of_ships + 1);
    $self->spaceport_id($port->id);
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
    my $empire = $self->body->empire;
    if ($self->type eq 'probe') {
        $empire->add_probe($self->foreign_star_id, $self->body_id);
        $empire->trigger_full_update;
        $self->delete;
    }
    
    elsif ($self->type eq 'spy_pod') {
        # trigger spy event on remote world
        $self->delete;
    }
    
    elsif ($self->type eq 'colony_ship') {
        if ($self->direction eq 'outgoing') {
            my $planet = $self->foreign_body;
            if ($planet->is_locked) {
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
                $empire->trigger_full_update(skip_put=>1);
                $empire->update;
                $self->delete;
            }
        }
        else {
            $self->land;
        }
    }
    
    elsif ($self->ship_type eq 'terraforming_platform_ship') {
        if ($self->direction eq 'outgoing') {
            my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::TerraformingLab');
            if (defined $lab) {
                $self->foreign_body->add_freebie('Lacuna::DB::Result::Building::Permanent::TerraformingPlatform', $lab->level)->update;
            }
        }
        else {
            $self->land;
        }
    }
    
    elsif ($self->ship_type eq 'gas_giant_settlement_platform_ship') {
        if ($self->direction eq 'outgoing') {
            my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::GasGiantLab');
            if (defined $lab) {
                $self->foreign_body->add_freebie('Lacuna::DB::Result::Building::Permanent::GasGiantPlatform', $lab->level)->update;
            }
        }
        else {
            $self->land;
        }
    }
    
    elsif ($self->ship_type eq 'mining_platform_ship') {
        if ($self->direction eq 'outgoing') {
            my $ministry = $self->body->mining_ministry;
            if (eval{$ministry->can_add_platform} && !$@) {
                $ministry->add_platform($self->foreign_body)->update;
            }
            else {
                $self->turn_around;
            }
        }
        else {
            $self->land;
        }
    }
    
    elsif ($self->ship_type eq 'cargo_ship') {
    }
    
    elsif ($self->ship_type eq 'smuggler_ship') {
    }
    
    elsif ($self->ship_type eq 'space_station') {
    }
    $self->delete;
}

# DISTANCE

sub calculate_travel_distance {
    my ($self, $target) = @_;
    return sqrt(abs($self->body->x - $target->x)**2 + abs($self->body->y - $target->y)**2) * 100;
}

sub calculate_travel_time {
    my ($self, $target) = @_;
    my $distance = $self->calculate_travel_distance($target);
    my $hours = $distance / $self->speed;
    my $seconds = 60 * 60 * $hours;
    return sprintf('%.0f', $seconds);
}



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
