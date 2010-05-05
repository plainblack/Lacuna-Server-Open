package Lacuna::DB::Result::Building::SpacePort;

use Moose;
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use List::Util qw(shuffle);

with 'Lacuna::Role::Distanced';
with 'Lacuna::Role::Shippable';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

sub send_probe {
    my ($self, $star) = @_;
    $self->remove_ship('probe');
    $self->save_changed_ports;
    my $duration = $self->calculate_seconds_from_body_to_star('probe', $self->body, $star);
    return Lacuna::DB::Result::TravelQueue->send(
        simpledb        => $self->simpledb,
        body            => $self->body,
        foreign_star    => $star,
        ship_type       => 'probe',
        direction       => 'outgoing',
        date_arrives    => DateTime->now->add(seconds=>$duration),
    );
}

sub send_spy_pod {
    my ($self, $target_body, $spy) = @_;
    my $ship = $self->send_ship_to_body($target_body, 'spy_pod', { spies => [ $spy->id ] }); 
    $spy->available_on($ship->date_arrives->clone);
    $spy->on_body_id($target_body->id);
    $spy->task('Travelling');
    $spy->put;
}

sub send_terraforming_platform_ship {
    my ($self, $target_body) = @_;
    return $self->send_ship_to_body($target_body, 'terraforming_platform_ship');
}

sub send_gas_giant_settlement_platform_ship {
    my ($self, $target_body) = @_;
    return $self->send_ship_to_body($target_body, 'gas_giant_settlement_platform_ship');
}

sub send_mining_platform_ship {
    my ($self, $target_body) = @_;
    return $self->send_ship_to_body($target_body, 'mining_platform_ship');
}

sub send_colony_ship {
    my ($self, $target_body) = @_;
    return $self->send_ship_to_body($target_body, 'mining_platform_ship');
}

sub send_ship_to_body {
    my ($self, $target_body, $type, $payload) = @_;
    my $body = $self->body;
    $self->remove_ship($type);
    $self->save_changed_ports;
    my $duration = $self->calculate_seconds_from_body_to_body($type, $body, $target_body);
    return Lacuna::DB::Result::TravelQueue->send(
        simpledb        => $self->simpledb,
        body            => $body,
        foreign_body    => $target_body,
        ship_type       => $type,
        direction       => 'outgoing',
        date_arrives    => DateTime->now->add(seconds=>$duration),
        payload         => $payload,
    );
}

sub ships_docked {
    my $self = shift;
    my $tally;
    foreach my $type (SHIP_TYPES) {
        my $docked = $type.'_count';
        $tally += $self->$docked;
    }
    return $tally;
}

sub docks_available {
    my $self = shift;
    return ($self->level * 2) - $self->ships_docked;
}

sub is_full {
    my ($self) = @_;
    return $self->docks_available ? 0 : 1;
}

has has_changed => (
    is  => 'rw',
    default => 0,
);

sub save_changed_ports {
    my $self = shift;
    if ($self->has_changed) {
        $self->put;
    }
    if ($self->has_other_ports) {
        foreach my $port (@{$self->other_ports}) {
            $port->put if ($self->has_changed);
        }
    }
}

has other_ports => (
    is  => 'rw',
    predicate => 'has_other_ports',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->simpledb->domain($self->class)->search( where => { class => $self->class, body_id => $self->body_id, 'itemName()' => ['!=', $self->id ] } )->to_array_ref;
    },
);

sub check_for_completed_ships {
    my $self = shift;
    my $ships = $self->simpledb->domain('ship_builds')->search( where => { body_id => $self->body_id, date_completed => ['<=', DateTime->now ]} );
    my %ports;
    while (my $ship = $ships->next) {
        my $port = $self->add_ship($ship->type);
        if (defined $port) {
            $ship->delete;
        }
        else {
            last;
        }
    }
}

sub add_ship {
    my ($self, $type) = @_;
    my $count = $type.'_count';
    if ($self->docks_available) {
        $self->$count( $self->$count + 1);
        $self->has_changed(1);
        return $self;
    }
    else { 
        foreach my $port (@{$self->other_ports}) {
            if ($port->docks_available) {
                $port->$count($self->$count + 1); # done this way rather than calling add on each to prevent infinite loop
                $port->has_changed(1);
            }
            return $port;
        }
        $type =~ s/_/ /g;
        my $body = $self->body;
        $self->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'ship_blew_up_at_port.txt',
            params      => [$type, $body->name],
        );
        $body->add_news(90,'Today, officials on %s are investigating the explosion of a %s at the Space Port.', $body->name, $type);
    }
}

sub remove_ship {
    my ($self, $type) = @_;
    $self->check_for_completed_ships;
    my $count = $type.'_count';
    if ($self->$count > 0) {
        $self->$count( $self->$count - 1);
        $self->has_changed(1);
        return $self;
    }
    else { 
        foreach my $port (@{$self->other_ports}) {
            if ($port->count > 0) {
                $port->$count($self->$count - 1); # done this way rather than calling remove on each to prevent infinite loop
                $port->has_changed(1);
                return $port;
            }
        }
        $self->save_changed_ports;
        $type =~ s/_/ /g;
        confess [ 1002, 'You do not have enough '.$type.'s.'];
    }
}


use constant controller_class => 'Lacuna::Building::SpacePort';

use constant university_prereq => 3;

use constant image => 'spaceport';

use constant name => 'Space Port';

use constant food_to_build => 160;

use constant energy_to_build => 180;

use constant ore_to_build => 220;

use constant water_to_build => 160;

use constant waste_to_build => 100;

use constant time_to_build => 300;

use constant food_consumption => 10;

use constant energy_consumption => 70;

use constant ore_consumption => 20;

use constant water_consumption => 12;

use constant waste_production => 20;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
