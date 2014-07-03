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
    alliance_id             => { data_type => 'int', is_nullable => 1 },
    influence               => { data_type => 'int', is_nullable => 0, default => 0 },
    recalc                  => { data_type => 'int', is_nullable => 0, default => 0 },
);

__PACKAGE__->belongs_to('station', 'Lacuna::DB::Result::Map::Body', 'station_id', { join_type => 'left', on_delete => 'set null' });
__PACKAGE__->belongs_to('alliance', 'Lacuna::DB::Result::Alliance', 'alliance_id', { join_type => 'left', on_delete => 'set null' });

__PACKAGE__->has_many('bodies', 'Lacuna::DB::Result::Map::Body', 'star_id');
__PACKAGE__->has_many('probes', 'Lacuna::DB::Result::Probes', 'star_id');

sub send_predefined_message {
    my ($self, %options) = @_;
    my $members = $self->bodies->search({empire_id => {'!=' => undef } });
    while (my $body = $members->next) {
        $body->empire->send_predefined_message(%options);
    }
}

sub is_seized {
    my ($self, $alliance_id) = @_;

    if ($self->alliance_id == $alliance_id and $self->influence >= 50) {
	return 1;
    }
    return;
}

# All stars that have had their influence changed need to be recalculated
#
sub recalc_influence {
    my ($self) = @_;

    # We will use some 'raw' SQL rather than go through the machinations of DBIC
    #
    my $dbh = $self->result_source->storage->dbh;
    my ($alliances) = $dbh->selectrow_array('select count(distinct(alliance_id)) from influence where star_id = ?', undef, $self->id) or die $dbh->errstr;
    my $alliance_id;
    my $influence = 0;
    if ($alliances == 0) {
        # Do nothing, star is not under the influence of any alliance
    }
    elsif ($alliances == 1) {
        ($alliance_id, $influence) = $dbh->selectrow_array(
            'select alliance_id,sum(influence) from influence where star_id=?',
            undef,
            $self->id) or die $dbh->errstr;
    }
    else {
        # Else we need the alliance with the greatest influence
        my $alliance_strength;
        ($alliance_id, $alliance_strength) = $dbh->selectrow_array(
            'select alliance_id,sum(influence) as best from influence where star_id=? group by alliance_id order by best desc limit 1', 
            undef, 
            $self->id) or die $dbh->errstr;
        # Subtract the influence of all other alliances from the top alliance
        ($influence) = $dbh->selectrow_array(
            'select ? - sum(influence) from influence where star_id=? and alliance_id != ?', 
            undef, 
            $alliance_strength, 
            $self->id, 
            $alliance_id) or die $dbh->errstr;
    }
    $self->recalc(0);
    $self->influence($influence);
    $self->alliance_id($alliance_id);
    $self->update;
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
