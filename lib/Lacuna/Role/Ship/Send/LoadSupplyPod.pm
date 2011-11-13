package Lacuna::Role::Ship::Send::LoadSupplyPod;

use strict;
use Moose::Role;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

requires 'supply_pod_level';

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
    $body->update;
    Lacuna->cache->set('supply_pod_sent',$self->body_id,1,60*60*24);
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1010, 'Cannot send more than one per day per planet.']
      if (Lacuna->cache->get('supply_pod_sent',$self->body_id));
};

1;
