package Lacuna::Role::Container;

use Moose::Role;
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
use Lacuna::Util qw(format_date commify);

requires "payload";

sub format_body_stats_for_log {
    my ($self, $body ) = @_;
    my %stats;
    foreach my $type (qw(water energy waste), ORE_TYPES, FOOD_TYPES) {
        $stats{$type} = $body->type_stored($type);
        $stats{food_capacity} = $body->food_capacity;
        $stats{water_capacity} = $body->water_capacity;
        $stats{waste_capacity} = $body->waste_capacity;
        $stats{ore_capacity} = $body->ore_capacity;
        $stats{energy_capacity} = $body->energy_capacity;
    }
    return \%stats;
}

sub unload {
    my ($self, $body, $withdraw) = @_;
    my $payload = $self->payload;
    #my $cargo_log = Lacuna->db->resultset('Lacuna::DB::Result::Log::Cargo');
    #$cargo_log->new({
    #    message     => 'payload to unload',
    #    body_id     => $body->id,
    #    data        => $payload,
    #    object_type => ref($self),
    #    object_id   => $self->id,
    #})->insert;
    #$cargo_log->new({
    #    message     => 'before unload',
    #    body_id     => $body->id,
    #    data        => $self->format_body_stats_for_log($body),
    #    object_type => ref($self),
    #    object_id   => $self->id,
    #})->insert;
    if (exists $payload->{prisoners}) {
        foreach my $id (@{$payload->{prisoners}}) {
            my $prisoner = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($id);
            next unless defined $prisoner;
            $prisoner->task('Captured');
            $prisoner->on_body_id($body->id);
            $prisoner->update;
        }
        delete $payload->{prisoners};
    }
    if (exists $payload->{mercenary}) {
        my $id = $payload->{mercenary};
        my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($id);
        next unless defined $spy;
        $spy->task('Idle');
        $spy->available_on(DateTime->now);
        $spy->on_body_id($body->id);
        unless ($withdraw) { 
            unless ($spy->empire_id == $body->empire_id) {
                $spy->empire_id($body->empire_id);
            }
            $spy->from_body_id($body->id);
        }
        $spy->update;
        delete $payload->{mercenary};
    }
    if (exists $payload->{ships}) {
        foreach my $id (@{$payload->{ships}}) {
            my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($id);
            next unless defined $ship;
            $ship->body_id($body->id);
            $ship->task('Docked');
            $ship->land->update;
        }
        delete $payload->{ships};
    }
    if (exists $payload->{essentia}) {
        $body->empire->add_essentia($payload->{essentia}, 'Trade Unloaded');
        $body->empire->update;
        delete $payload->{essentia};
    }
    if (exists $payload->{resources}) {
        my %resources = %{$payload->{resources}};
        foreach my $type (keys %resources) {
            $body->add_type($type, $resources{$type});
        }
        $body->update;
        delete $payload->{resources};
    }
    if (exists $payload->{plans}) {
        foreach my $plan (@{$payload->{plans}}) {
            $body->add_plan($plan->{class}, $plan->{level}, $plan->{extra_build_level});
        }
        delete $payload->{plans};
    }
    if (exists $payload->{glyphs}) {
        foreach my $glyph (@{$payload->{glyphs}}) {
            $body->add_glyph($glyph);
        }
        delete $payload->{glyphs};
    }
    #$cargo_log->new({
    #    message     => 'after unload',
    #    body_id     => $body->id,
    #    data        => $self->format_body_stats_for_log($body),
    #    object_type => ref($self),
    #    object_id   => $self->id,
    #})->insert;
    $self->payload($payload);
    return $self;
}

sub consolidate {
  my ($items) = @_;

  my %items;
  my @items;
  for my $item (@$items) {
    $items{$item}++;
  }
  for my $item (sort keys %items) {
    push @items, sprintf("%5s %s", commify($items{$item}), $item);
  }
  return \@items;
}

sub format_description_of_payload {
    my ($self) = @_;
    my @items;
    my @scratch;
    my $payload = $self->payload;
    
    # essentia
    push @items, sprintf('%s essentia.', commify($payload->{essentia})) if ($payload->{essentia});
    
    # resources
    foreach my $resource (keys %{ $payload->{resources}}) {
        push @items, sprintf('%s %s', commify($payload->{resources}{$resource}), $resource);
    }
    
    # glyphs
    @scratch = ();
    foreach my $glyph (@{$payload->{glyphs}}) {
        push @scratch, $glyph.' glyph';
    }
    push @items, @{consolidate(\@scratch)};
    
    # ships
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    
    @scratch = ();
    foreach my $id (@{ $payload->{ships}}) {
      my $ship = $ships->find($id);
      next unless defined $ship;
      my $pattern = '%s (speed: %s, stealth: %s, hold size: %s, berth: %s, combat: %s)' ;
      push @scratch,
           sprintf($pattern,
                   $ship->type_formatted,
                   commify($ship->speed),
                   commify($ship->stealth),
                   commify($ship->hold_size),
                   commify($ship->berth_level),
                   commify($ship->combat));
    }
    push @items, @{consolidate(\@scratch)};

    # plans
    @scratch = ();
    foreach my $stats (@{ $payload->{plans}}) {
        my $level = $stats->{level};
        if ($stats->{extra_build_level}) {
            $level .= '+'.$stats->{extra_build_level};
        }
        my $pattern = '%s (%s) plan'; 
        push @scratch, sprintf($pattern, $stats->{class}->name, $level);
    }
    push @items, @{consolidate(\@scratch)};
    
    # spies
    @scratch = ();
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    if (exists $payload->{spies}) {
        foreach my $id (@{$payload->{spies}}) {
            my $spy = $spies->find($id);
            next unless defined $spy;
            push @scratch, 'Level '.$spy->level.' spy named '.$spy->name . ' (transport)';
        }
    }
    push @items, @{consolidate(\@scratch)};
    
    # prisoners
    @scratch = ();
    if (exists $payload->{prisoners}) {
        foreach my $id (@{$payload->{prisoners}}) {
            my $spy = $spies->find($id);
            next unless defined $spy;
            push @scratch, 'Level '.$spy->level.' spy named '.$spy->name . ' (prisoner) sentence expires '.$spy->format_available_on;
        }
    }
    push @items, @{consolidate(\@scratch)};
    
    # fetch spies
    @scratch = ();
    if (exists $payload->{fetch_spies}) {
        foreach my $id (@{$payload->{fetch_spies}}) {
            my $spy = $spies->find($id);
            push @scratch, 'Level '.$spy->level.' spy named '.$spy->name . ' (fetch upon arrival)';
        }
    }
    
    return \@items;
}


1;
