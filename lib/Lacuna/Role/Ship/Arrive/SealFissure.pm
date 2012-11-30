package Lacuna::Role::Ship::Arrive::SealFissure;

use strict;
use Moose::Role;
use Lacuna::Util qw(randint);
use DateTime;
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

after handle_arrival_procedures => sub {
    my ($self) = @_;

    # we're coming home
    return if ($self->direction eq 'in');

    # Turn around if occupied
    return if ($self->foreign_body->empire_id);

    my $amount = 0;
    my $payload = $self->payload;
    foreach my $type (ORE_TYPES) {
        if (defined($payload->{resources}{$type})) {
            $amount += $payload->{resources}{$type};
        }
    }
    # determine target building
    my $building;
    my $body_hit = $self->foreign_body;
    my ($fissure) = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::Fissure'} @{$body_hit->building_cache};
    return if not defined $fissure;
    
    $body_hit->add_news(70, sprintf('An attempt to fix the fissure on %s happened today.', $body_hit->name));

    # handle fissure
    if (defined $fissure) {
        my $curr_eff = $fissure->efficiency + int($amount/1_000_000) + 1;
        $curr_eff = 100 if $curr_eff > 100;
        my $curr_lev = $fissure->level;

        my $down_chance = $curr_eff;
	$down_chance = 5 if ($down_chance < 5);
        $down_chance = 95 if ($down_chance > 95);

        if ( $down_chance > randint(0,99) ) {
            $curr_lev--;
            $curr_eff = 10;
        }
        if ($curr_lev < 1) {
            $fissure->delete;
            $self->body->empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'we_destroyed_a_fissure.txt',
                params      => [$self->type_formatted, $body_hit->x, $body_hit->y, $body_hit->name ],
            );
        }
        else {
            $fissure->level($curr_lev);
            $fissure->efficiency($curr_eff);
            $fissure->update;
            $self->body->empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'our_ship_hit_fissure.txt',
                params      => [$self->type_formatted, $body_hit->x, $body_hit->y, $body_hit->name, $curr_lev, $curr_eff ],
            );
        }
        $self->delete;
        $body_hit->needs_surface_refresh(1);
        $body_hit->update;
    }
    
    confess [-1];
};

after send => sub {
    my $self = shift;
    my $part = $self->hold_size;
    my $ore = $part;
    my $body = $self->body;
    my $payload;
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
    $self->payload($payload);
    $self->update;
    $body->update;
};

1;
