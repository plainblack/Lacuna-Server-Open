package Lacuna::DB::Result::Map::Star;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map';
use Lacuna::Util;

__PACKAGE__->table('star');
__PACKAGE__->add_columns(
    color                   => { data_type => 'varchar', size => 7, is_nullable => 0 },
    station_id              => { data_type => 'int', is_nullable => 1 },
);

__PACKAGE__->has_many('bodies', 'Lacuna::DB::Result::Map::Body', 'star_id');
__PACKAGE__->has_many('probes', 'Lacuna::DB::Result::Probes', 'star_id');
__PACKAGE__->has_many('laws', 'Lacuna::DB::Result::Laws', 'star_id');
__PACKAGE__->belongs_to('station', 'Lacuna::DB::Result::Map::Body', 'station_id', { on_delete => 'set null' });

sub send_predefined_message {
    my ($self, %options) = @_;
    my $members = $self->bodies->search({empire_id => {'!=' => undef } });
    while (my $body = $members->next) {
        $body->empire->send_predefined_message(%options);
    }
}

sub get_status_lite {
    my ($self, $empire, $override_probe) = @_;

    my $out = {
        color   => $self->color,
        id      => $self->id,
        name    => $self->name,
        x       => $self->x,
        y       => $self->y,
        zone    => $self->zone,
    };
    if ($self->station_id) {
        my $station     = $self->station;
        my $alliance    = $station->alliance;
        $out->{station} = {
            id      => $station->id,
            x       => $station->x,
            y       => $station->y,
            name    => $station->name,
            alliance => {
                id      => $alliance->id,
                name    => $alliance->name,
            },
        };
    }
    if (defined $empire) {
        if ($override_probe or $self->id ~~ $empire->probed_stars) {
            my @orbits;
            my $bodies = $self->bodies;
            while (my $body = $bodies->next) {
                push @orbits, $body->get_status_lite($empire);
            }
            $out->{bodies} = \@orbits;
        }
    }
    return $out;
}

sub get_status {
    my ($self, $empire, $override_probe) = @_;
    my $out = {
        color           => $self->color,
        name            => $self->name,
        id              => $self->id,
        x               => $self->x,
        y               => $self->y,
        zone            => $self->zone,
    };
    if (defined $empire) {
        if ($override_probe || $self->id ~~ $empire->probed_stars) {
            my @orbits;
            my $bodies = $self->bodies;
            while (my $body = $bodies->next) {
                push @orbits, $body->get_status($empire);
            }
            $out->{bodies} = \@orbits;
            if ($self->station_id) {
                my $station = $self->station;
                $out->{station} = {
                    id      => $station->id,
                    x       => $station->x,
                    y       => $station->y,
                    name    => $station->name,
                };
            }
        }
    }
    return $out;
}




no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
