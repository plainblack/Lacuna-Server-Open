package Lacuna::Role::Ship::Arrive::DeploySupplyPod;

use strict;
use Moose::Role;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

requires 'supply_pod_level';

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');
    
    # deploy the pod
    my $body = $self->foreign_body;
    my ($x, $y) = eval{$body->find_free_space};
    unless ($@) {
        my $deployed = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
            class       => 'Lacuna::DB::Result::Building::SupplyPod',
            x           => $x,
            y           => $y,
            level       => $self->supply_pod_level - 1,
        });
        $body->build_building($deployed, 1);
        $deployed->finish_upgrade;
        $body->recalc_stats;
        my $payload = $self->payload;
        if (exists $payload->{resources}) {
            my %resources = %{$payload->{resources}};
            foreach my $type (keys %resources) {
                $body->add_type($type, $resources{$type});
            }
        }
        $body->update;
    }

    # all pow
    $self->delete;
    confess [-1];
};


after send => sub {
    my $self = shift;
    my $part = $self->hold_size;
    my $food = $part;
    my $ore = $part;
    my $body = $self->body;
    my $payload;
    foreach my $type (shuffle FOOD_TYPES) {
        my $stored = $body->type_stored($type);
        if ($stored >= $food) {
            $body->spend_type($type, $food);
            $payload->{resources}{$type} = $food;
            last;
        }
        else {
            $body->spend_type($type, $stored);
            $payload->{resources}{$type} = $stored if $stored;
            $food -= $stored;
        }
    }
    foreach my $type (shuffle ORE_TYPES) {
        my $stored = $body->type_stored($type);
        if ($stored >= $ore) {
            $body->spend_type($type, $ore);
            $payload->{resources}{$type} = $ore;
            last;
        }
        else {
            $body->spend_type($type, $stored);
            $payload->{resources}{$type} = $stored if $stored;
            $ore -= $stored;
        }
    }
    my $energy = $body->type_stored('energy');
    if ($energy >= $part) {
        $body->spend_type('energy', $part);
        $payload->{resources}{energy} = $part;
    }
    else {
        $body->spend_type('energy', $energy);
        $payload->{resources}{energy} = $energy if $energy;
    }
    my $water = $body->type_stored('water');
    if ($water >= $part) {
        $body->spend_type('water', $part);
        $payload->{resources}{water} = $part;
    }
    else {
        $body->spend_type('water', $water);
        $payload->{resources}{water} = $water if $water;
    }
    $self->payload($payload);
    $self->update;
    Lacuna->cache->get('supply_pod_sent',$self->body_id,1,60*60*24);
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1010, 'Cannot send more than one per day per planet.'] if (Lacuna->cache->get('supply_pod_sent',$self->body_id));
};


1;
