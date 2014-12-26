package Lacuna::Role::Container;

use Moose::Role;
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
use Lacuna::Util qw(format_date commify consolidate_items);

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
        $body->empire->add_essentia({
            amount  => $payload->{essentia}, 
            reason  => 'Trade Unloaded',
        });
        $body->empire->update;
        delete $payload->{essentia};
    }
    if (exists $payload->{resources}) {
        my %resources = %{$payload->{resources}};
        $body->update;
        $body->discard_changes;
        foreach my $type (keys %resources) {
            $body->add_type($type, $resources{$type});
        }
        $body->update;
        delete $payload->{resources};
    }
    if (exists $payload->{plans}) {
        foreach my $plan (@{$payload->{plans}}) {
            $body->add_plan($plan->{class}, $plan->{level}, $plan->{extra_build_level}, $plan->{quantity});
        }
        delete $payload->{plans};
    }
    if (exists $payload->{glyphs}) {
        foreach my $glyph (@{$payload->{glyphs}}) {
            $body->add_glyph($glyph->{name}, $glyph->{quantity});
        }
        delete $payload->{glyphs};
    }
    $self->payload($payload);
    return $self;
}

sub format_description_of_payload {
    my ($self) = @_;
    my $item_arr = [];
    my $scratch;
    my $payload = $self->payload;
    
    # essentia
    push @{$item_arr}, sprintf('%s essentia.', commify($payload->{essentia})) if ($payload->{essentia});
  
    # resources
    foreach my $resource (keys %{ $payload->{resources}}) {
        push @{$item_arr}, sprintf('%s %s', commify($payload->{resources}{$resource}), $resource);
    }
    
    # glyphs
    foreach my $glyph (@{$payload->{glyphs}}) {
        push @{$item_arr}, sprintf('%s %s glyph', commify($glyph->{quantity}), $glyph->{name});
    }
    
    # ships
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    
    undef $scratch;
    foreach my $id (@{ $payload->{ships}}) {
        my $ship = $ships->find($id);
        next unless defined $ship;
        my $pattern = '%s (speed: %s, stealth: %s, hold size: %s, berth: %s, combat: %s)' ;
        push @{$scratch},
            sprintf($pattern,
                $ship->type_formatted,
                commify($ship->speed),
                commify($ship->stealth),
                commify($ship->hold_size),
                commify($ship->berth_level),
                commify($ship->combat));
    }
    push @{$item_arr}, @{consolidate_items($scratch)} if (defined($scratch));

    #fleets
    undef $scratch;
    foreach my $fleet (sort keys %{$payload->{fleet}}) {
        my $pattern = '%s (speed: %s, stealth: %s, hold size: %s, combat: %s #: %d)' ;
        push @{$scratch},
            sprintf($pattern,
                $payload->{fleet}->{$fleet}->{type},
                commify($payload->{fleet}->{$fleet}->{speed}),
                commify($payload->{fleet}->{$fleet}->{stealth}),
                commify($payload->{fleet}->{$fleet}->{hold_size}),
                commify($payload->{fleet}->{$fleet}->{combat}),
                commify($payload->{fleet}->{$fleet}->{quantity}));
    }
    push @{$item_arr}, @{consolidate_items($scratch)} if (defined($scratch));

    # plans
    undef $scratch;
    foreach my $stats (@{ $payload->{plans}}) {
        my $level = $stats->{level};
        if ($stats->{extra_build_level}) {
            $level .= '+'.$stats->{extra_build_level};
        }
        my $pattern = '%s (%s) plan'; 
        push @{$item_arr}, sprintf('%s %s (%s) plan', $stats->{quantity}, $stats->{class}->name, $level);
    }
    
    # spies
    undef $scratch;
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    if (exists $payload->{spies}) {
        foreach my $id (@{$payload->{spies}}) {
            my $spy = $spies->find($id);
            next unless defined $spy;
            push @{$scratch}, 'Level '.$spy->level.' spy named '.$spy->name . ' (transport)';
        }
        push @{$item_arr}, @{consolidate_items($scratch)} if (defined($scratch));
    }
   
    # prisoners
    undef $scratch;
    if (exists $payload->{prisoners}) {
        foreach my $id (@{$payload->{prisoners}}) {
            my $spy = $spies->find($id);
            next unless defined $spy;
            push @{$scratch}, 
                'Level '.$spy->level.' spy named '.$spy->name .
                ' (prisoner) sentence expires '.$spy->format_available_on;
        }
        push @{$item_arr}, @{consolidate_items($scratch)} if (defined($scratch));
    }
    
    # fetch spies
    undef $scratch;
    if (exists $payload->{fetch_spies}) {
        foreach my $id (@{$payload->{fetch_spies}}) {
            my $spy = $spies->find($id);
            next unless defined $spy;
            push @{$scratch}, 'Level '.$spy->level.' spy named '.$spy->name . ' (fetch upon arrival)';
        }
        push @{$item_arr}, @{consolidate_items($scratch)} if (defined($scratch));
    }
    
    return $item_arr;
}

1;
