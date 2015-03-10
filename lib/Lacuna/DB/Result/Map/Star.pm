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
    influence               => { data_type => 'int', is_nullable => 1 },
    needs_recalc            => { data_type => 'tinyint', is_nullable => 0, default_value => 0 },
);

__PACKAGE__->has_many('bodies', 'Lacuna::DB::Result::Map::Body', 'star_id');
__PACKAGE__->has_many('probes', 'Lacuna::DB::Result::Probes', 'star_id');
__PACKAGE__->has_many('laws', 'Lacuna::DB::Result::Laws', 'star_id');
__PACKAGE__->belongs_to('station', 'Lacuna::DB::Result::Map::Body', 'station_id', { on_delete => 'set null' });

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    my $schema = $sqlt_table->schema;
    $sqlt_table->add_index(name => 'idx_recalc', fields => ['needs_recalc']);
}

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
        influence => $self->influence,
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
        influence       => $self->influence,
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

#,}}}
sub recalc_influence {
    my ($self) = @_;

    if ($self->in_neutral_area or $self->in_starter_zone) {
        # this should never really happen.
        $self->needs_recalc(0);
        $self->influence(0);
        $self->station_id(undef);
        $self->update;
        return;
    }

    my $station_id;
    my $influence = 0;

    my $rs = Lacuna->db->resultset('StationInfluence');
    my $inf = $rs->search(
                          { star_id => $self->id },
                          {
                              select => [
                                         'alliance_id',
                                         { sum => \[ $rs->sql_currentinfluence ], -as => 'totalinfluence' }
                                        ],
                              as => [ qw/alliance_id totalinfluence/ ],
                              group_by => 'alliance_id',
                              order_by => { -desc => 'totalinfluence' },
                          });
    my $best = $inf->next();
    # is there any influence?
    if ($best) {
        $influence = $best->get_column('totalinfluence');
        while (my $i = $inf->next())
        {
            $influence -= $i->get_column('totalinfluence');
        }

        if ($influence > 100)
        {
            # and now we have to figure out which station of
            # the winner's alliance is the strongest.
            my $row = $rs->with_currentinfluence->find({ star_id => $self->id, alliance_id => $best->alliance_id },{order_by => {-desc => 'currentinfluence'}, rows => 1});
            $station_id = $row->station_id;
        }
        else
        {
            # not enough to overcome competition, so not owned
            $influence = 0;
        }
    }
    # else, if no influencers, everything left at uninfluenced.

    $self->needs_recalc(0);
    $self->influence($influence);
    $self->station_id($station_id);
    $self->update;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
