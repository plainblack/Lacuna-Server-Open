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
    my ($self, $body) = @_;
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
        $spy->empire_id($body->empire_id);
        $spy->from_body_id($body->id);
        $spy->on_body_id($body->id);
        $spy->available_on(DateTime->now);
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

sub format_description_of_payload {
    my ($self) = @_;
    my @items;
    my $payload = $self->payload;
    
    # essentia
    push @items, sprintf('%s essentia.', commify($payload->{essentia})) if ($payload->{essentia});
    
    # resources
    foreach my $resource (keys %{ $payload->{resources}}) {
        push @items, sprintf('%s %s', commify($payload->{resources}{$resource}), $resource);
    }
    
    # glyphs
    foreach my $glyph (@{$payload->{glyphs}}) {
        push @items, $glyph.' glyph';
    }
    
    # ships
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    foreach my $id (@{ $payload->{ships}}) {
        my $ship = $ships->find($id);
        next unless defined $ship;
        my $pattern = '%s (speed: %s, stealth: %s, hold size: %s, combat: %s)' ;
        push @items, sprintf($pattern, $ship->type_formatted, commify($ship->speed), commify($ship->stealth), commify($ship->hold_size), commify($ship->combat));
    }

    # plans
    foreach my $stats (@{ $payload->{plans}}) {
        my $level = $stats->{level};
        if ($stats->{extra_build_level}) {
            $level .= '+'.$stats->{extra_build_level};
        }
        my $pattern = '%s (%s) plan'; 
        push @items, sprintf($pattern, $stats->{class}->name, $level);
    }
    
    # spies
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    if (exists $payload->{spies}) {
        foreach my $id (@{$payload->{spies}}) {
            my $spy = $spies->find($id);
            next unless defined $spy;
            push @items, 'Level '.$spy->level.' spy named '.$spy->name . ' (transport)';
        }
    }
    
    # prisoners
    if (exists $payload->{prisoners}) {
        foreach my $id (@{$payload->{prisoners}}) {
            my $spy = $spies->find($id);
            next unless defined $spy;
            push @items, 'Level '.$spy->level.' spy named '.$spy->name . ' (prisoner) sentence expires '.$spy->format_available_on;
        }
    }
    
    # fetch spies
    if (exists $payload->{fetch_spies}) {
        foreach my $id (@{$payload->{fetch_spies}}) {
            my $spy = $spies->find($id);
            push @items, 'Level '.$spy->level.' spy named '.$spy->name . ' (fetch upon arrival)';
        }
    }
    
    return \@items;
}


1;
