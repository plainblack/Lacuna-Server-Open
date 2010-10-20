package Lacuna::Role::Container;

use Moose::Role;
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);

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
    my ($self, $payload, $body) = @_;
    my $cargo_log = Lacuna->db->resultset('Lacuna::DB::Result::Log::Cargo');
    $cargo_log->new({
        message     => 'payload to unload',
        body_id     => $body->id,
        data        => $payload,
        object_type => ref($self),
        object_id   => $self->id,
    })->insert;
    $cargo_log->new({
        message     => 'before unload',
        body_id     => $body->id,
        data        => $self->format_body_stats_for_log($body),
        object_type => ref($self),
        object_id   => $self->id,
    })->insert;
    if (exists $payload->{prisoners}) {
        foreach my $id (@{$payload->{prisoners}}) {
            my $prisoner = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($id);
            $prisoner->task('Captured');
            $prisoner->on_body_id($body->id);
            $prisoner->update;
        }
        delete $payload->{prisoners};
    }
    if (exists $payload->{ships}) {
        foreach my $id (@{$payload->{ships}}) {
            my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($id);
            $ship->task('Docked');
            $ship->body_id($body->id);
            $ship->update;
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
    $cargo_log->new({
        message     => 'after unload',
        body_id     => $body->id,
        data        => $self->format_body_stats_for_log($body),
        object_type => ref($self),
        object_id   => $self->id,
    })->insert;
}


1;
