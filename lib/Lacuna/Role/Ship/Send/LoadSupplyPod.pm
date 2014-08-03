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
    my $food_stored = 0;
    my $food_type_count = 0;
    for my $type (FOOD_TYPES) {
      my $stored = $body->type_stored($type);
      $food_stored += $stored;
      $food_type_count++ if ($stored);
    }
    $food = $food_stored if ($food > $food_stored);
    foreach my $type (FOOD_TYPES) {
        my $stored = $body->type_stored($type);
        if ($stored) {
          my $amt = int(($food * $stored)/$food_stored) - 100;
          if ( $amt > 0 ) {
            $body->spend_type($type, $amt);
            $payload->{resources}{$type} = $amt;
          }
        }
    }
    my $ore_stored = 0;
    my $ore_type_count = 0;
    for my $type (ORE_TYPES) {
      my $stored = $body->type_stored($type);
      $ore_stored += $stored;
      $ore_type_count++ if ($stored);
    }
    $ore = $ore_stored if ($ore > $ore_stored);
    foreach my $type (ORE_TYPES) {
        my $stored = $body->type_stored($type);
        if ($stored) {
          my $amt = int(($ore * $stored)/$ore_stored) - 100;
          if ( $amt > 0 ) {
            $body->spend_type($type, $amt);
            $payload->{resources}{$type} = $amt;
          }
        }
    }
    my $energy = $body->type_stored('energy') - 100;
    if ($energy >= $part) {
        $body->spend_type('energy', $part);
        $payload->{resources}{energy} = $part;
    }
    elsif ($energy > 0) {
        $body->spend_type('energy', $energy);
        $payload->{resources}{energy} = $energy if $energy;
    }
    else {
        $payload->{resources}{energy} = 0;
    }
    my $water = $body->type_stored('water') - 100;
    if ($water >= $part) {
        $body->spend_type('water', $part);
        $payload->{resources}{water} = $part;
    }
    elsif ($water > 0) {
        $body->spend_type('water', $water);
        $payload->{resources}{water} = $water if $water;
    }
    else {
      $payload->{resources}{water} = 0;
    }
    $self->payload($payload);
    $self->update;
    $body->update;

    $self->body->get_a_building("PlanetaryCommand")->sent_a_pod;
};

after can_send_to_target => sub {
    my ($self, $target) = @_;
    if (not $self->body->get_a_building("PlanetaryCommand")->can_send_pod) {
        confess [1010, 'Cannot send another supply pod so soon after sending previous supply pod.'];
    }
};

1;
