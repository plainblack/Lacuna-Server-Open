package Lacuna::DB::Result::Building::SpacePort;

use Moose;
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use List::Util qw(shuffle);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

__PACKAGE__->has_many('ships', 'Lacuna::DB::Result::Ships', 'spaceport_id');

sub send_probe {
    my ($self, $star) = @_;
    return $self->send_ship($star, 'probe');
}

sub send_spy_pod {
    my ($self, $target_body, $spy) = @_;
    my $ship = $self->send_ship($target_body, 'spy_pod', { spies => [ $spy->id ] }); 
    $spy->available_on($ship->date_available->clone);
    $spy->on_body_id($target_body->id);
    $spy->task('Travelling');
    $spy->update;
    return $ship;
}

sub send_terraforming_platform_ship {
    my ($self, $target_body) = @_;
    return $self->send_ship($target_body, 'terraforming_platform_ship');
}

sub send_gas_giant_settlement_platform_ship {
    my ($self, $target_body) = @_;
    return $self->send_ship($target_body, 'gas_giant_settlement_platform_ship');
}

sub send_mining_platform_ship {
    my ($self, $target_body) = @_;
    return $self->send_ship($target_body, 'mining_platform_ship');
}

sub send_colony_ship {
    my ($self, $target_body) = @_;
    return $self->send_ship($target_body, 'mining_platform_ship');
}

sub send_ship {
    my ($self, $target, $type, $payload) = @_;
    my $ship = $self->find_ship($type);
    return $ship->send(
        target      => $target,
        payload     => $payload,   
    );
}

has number_of_ships => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->ships->count;
    },
);

sub docks_available {
    my $self = shift;
    return ($self->level * 2) - $self->number_of_ships;    
}

sub is_full {
    my ($self) = @_;
    return $self->docks_available ? 0 : 1;
}

has other_ports => (
    is  => 'rw',
    predicate => 'has_other_ports',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @ports = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search( { class => $self->class, body_id => $self->body_id, id => {'!=', $self->id } } )->all;
        return \@ports;
    },
);

sub find_open_dock {
    my ($self) = @_;
    if ( $self->docks_available ) {
        return $self;
    }
    else {
        foreach my $port (@{$self->other_ports}) {
            if ( $port->docks_available ) {
                return $port;
            }
        }
    }
    return undef;
}

sub find_ship {
    my ($self, $type) = @_;
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $self->body_id, task => 'Docked', type => $type})->single;
    unless (defined $ship ) {
        $type =~ s/_/ /g;
        confess [ 1002, 'You do not have enough '.$type.'s.'];
    }
    return $ship;
}

before delete => sub {
    my ($self) = @_;
    Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({spaceport_id => $self->id })->delete_all;
};


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
