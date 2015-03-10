package Lacuna::DB::Result::Map::Body::Planet::Station;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';
use Lacuna::Util qw(randint);
use Lacuna::Constants qw(MINIMUM_EXERTABLE_INFLUENCE);
use Data::Dumper;

use constant image => 'station';
__PACKAGE__->has_many('propositions','Lacuna::DB::Result::Propositions','station_id');
__PACKAGE__->has_many('laws','Lacuna::DB::Result::Laws','station_id');
__PACKAGE__->has_many('stars','Lacuna::DB::Result::Map::Star','station_id');

has parliament => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_parliament',
);

sub _build_parliament {
    my ($self) = @_;

    my ($parliament) = grep {$_->class =~ /Parliament$/} @{$self->building_cache};
    return $parliament;
}

around get_status => sub {
    my ($orig, $self, $empire) = @_;
    my $out = $orig->($self, $empire);
    if (defined $self->alliance) {
        $out->{alliance} = {
            id      => $self->alliance->id,
            name    => $self->alliance->name,
        };
        $out->{influence} = {
            spent => $self->influence_spent,
            total => $self->total_influence,
        };
    }
    return $out;
};

sub has_room_in_build_queue {
    return 1;   
}

before sanitize => sub {
    my $self = shift;
    $self->propositions->delete_all;
    $self->laws->delete_all;
};

after sanitize => sub {
    my $self = shift;
    $self->update({
        size        => randint(1,10),
        class       => 'Lacuna::DB::Result::Map::Body::Asteroid::A21',
        alliance_id => undef,
    });
};

has command => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_command',
);

sub _build_command {
    my ($self) = @_;
    my ($building) = grep {$_->class =~ /StationCommand$/} @{$self->building_cache};
    return $building;
}

sub has_resources_to_operate {
    return 1;
}

sub has_resources_to_operate_after_building_demolished {
    return 1;
}

sub spend_happiness {
    my $self = shift;
    return $self;
}

sub add_happiness {
    my $self = shift;
    return $self;
}

sub spend_waste {
    my $self = shift;
    return $self;
}

sub add_waste {
    my $self = shift;
    return $self;
}

sub in_jurisdiction {
    my ($self, $target) = @_;
    if (ref $target eq 'Lacuna::DB::Result::Map::Star') {
        my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($target->id);
        unless (defined $star) {
            confess [1009, 'Invalid star'];
        }
        unless ($star->station_id == $self->id) {
            confess [1009, 'Target star is not in the station\'s jurisdiction.'];
        }
    } else {
        my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target->id);
        unless (defined $body) {
            confess [1009, 'Invalid body'];
        }
        unless ($body->star->station_id == $self->id) {
            confess [1009, 'Target body is not in the station\'s jurisdiction.'];
        }
    }
}

has total_influence => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_total_influence',
);

sub _build_total_influence {
    my ($self) = @_;

    my $influence = 0;
    foreach my $building (@{$self->building_cache}) {
        if (
            $building->class eq 'Lacuna::DB::Result::Building::Module::IBS' or
            $building->class eq 'Lacuna::DB::Result::Building::Module::OperaHouse' or
            $building->class eq 'Lacuna::DB::Result::Building::Module::CulinaryInstitute' or
            $building->class eq 'Lacuna::DB::Result::Building::Module::ArtMuseum'
            ) {
            $influence += $building->effective_level;
        }
    }
    return $influence;
}

has influence_spent => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->stars->count;
    },
);

sub influence_remaining {
    my $self = shift;
    return $self->total_influence - $self->influence_spent;
}

has range_of_influence => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_range_of_influence',
);

sub _build_range_of_influence {
    my ($self) = @_;

    my $range = 0;
    my ($ibs) = grep {$_->class eq 'Lacuna::DB::Result::Building::Module::IBS'} @{$self->building_cache};
    if (defined $ibs) {
        $range = $ibs->level * 300;
    }
    return $range;
}

sub in_range_of_influence {
    my ($self, $star) = @_;
    # measure influence not from the station, but from its star.
    if ($self->star->calculate_distance_to_target($star) > $self->range_of_influence) {
        return;
    }
    return 1;
}



sub update_influence {
    my $self = shift;
    my $opts = shift || {};
    my $starttime = $opts->{starttime} || DateTime->now;

    my $range = $self->range_of_influence() / 100;
    my $influence = $self->total_influence;
    my $centerpoint = $self->star;

    # if the station is in NZ or SZ, it exerts no influence, period.
    if ($centerpoint->in_neutral_area() or $centerpoint->in_starter_zone())
    {
        # delete any influence it may have.
        my $si = Lacuna->db->resultset('StationInfluence')->search({station_id => $self->id})->delete;
        return;
    }

    my $calc_influence = sub {
        int( $influence * $influence * 23 /
            ($_[0] * $_[0] + 0.01) # distance can be zero for same-star, so avoid divide-by-zero
           );
    };

    # find any stars influenced outside of our range.
    # We can't simply delete directly because there's a trigger to update
    # the star table, and we're already using the star table.
    # Thus, grab the influence IDs affected, then we can delete them.
    my $dbh = Lacuna->db->storage->dbh;
    my $sth = $dbh->prepare_cached(<<'EOSQL');
    SELECT ID
      FROM stationinfluence si
    WHERE
      si.station_id = ?
        AND
      exists (SELECT 1
                FROM star s
              WHERE
                s.id = si.star_id
              AND
                pow(pow(x - ?, 2) + pow(y - ?, 2), 0.5) > ?
             )
EOSQL
    $sth->execute(
                  $self->id,
                  $centerpoint->x, $centerpoint->y, #,,,
                  $range
                 );
    my $all_ids = $sth->fetchall_arrayref();

    # any deletions?
    if (@$all_ids)
    {
        my $si = Lacuna->db->resultset('StationInfluence');
        $si->search({ id => { -in => [ map { @$_ } @$all_ids ] } })->delete;
    }

    # look for any stars we are influencing that have changed influence.
    # (one of the influence buildings have changed strength)
    my $home_star = Lacuna->db->resultset('StationInfluence')->find({station_id => $self->id, star_id => $self->star_id});
    if (!$home_star || $calc_influence->(0) != $home_star->influence )
    {
        my $rs = Lacuna->db->resultset('StationInfluence');
        my $influence_rs = $rs->
            search(
                   { 'me.station_id' => $self->id },
                   { 
                       join => 'star',
                       '+select' => [
                                     \[ $rs->sql_currentinfluence . ' as currentinfluence' ],
                                     \[ 'pow(pow(star.x - ?, 2) + pow(star.y - ?, 2), 0.5) as distance', $centerpoint->x, $centerpoint->y, ], #,
                                    ],
                       '+as' => [ 'currentinfluence', 'distance' ],
                   }
                  );
        while (my $inf = $influence_rs->next)
        {
            $inf->influence($calc_influence->($inf->get_column('distance')));
            $inf->oldstart($starttime);
            $inf->oldinfluence($inf->currentinfluence);
            $inf->update;
        }
    }

    # now, look for any new stars we can influence.
    my $stars_rs = Lacuna->db->resultset('Map::Star')->search({
        -and => [
                 \[ 'pow(pow(me.x - ?, 2) + pow(me.y - ?, 2), 0.5) < ?', $centerpoint->x, $centerpoint->y, $range ], #,,
                 \[ 'NOT EXISTS (SELECT 1 FROM stationinfluence si WHERE si.station_id = ? AND me.id = si.star_id)', $self->id ],
                ],
    },{
        '+select' => [
                      \[ 'pow(pow(me.x - ?, 2) + pow(me.y - ?, 2), 0.5) as distance', $centerpoint->x, $centerpoint->y, ], #,
                     ],
        '+as' => [ 'distance' ],
        order_by => 'distance',
    });

        $|++;

    while (my $star = $stars_rs->next)
    {
        next if $star->in_neutral_area() or $star->in_starter_zone();

        my $distance = $star->get_column('distance');
        my $target_influence = $calc_influence->($distance);

        # anything under MINIMUM_EXERTABLE_INFLUENCE is too weak to help/hinder influence of anything
        # (also keeps the influence table from blowing up over all the IBS30s)
        if ($target_influence > MINIMUM_EXERTABLE_INFLUENCE)
        {
            my $inf = Lacuna->db->resultset('StationInfluence')->
                create(
                       {
                           station_id        => $self->id,
                           star_id           => $star->id,
                           alliance_id       => $self->alliance_id,
                           oldinfluence      => 0, # start out with no influence
                           oldstart          => $starttime,
                           started_influence => $starttime,
                           influence         => $target_influence,
                       }
                      );
            $inf->update;
        }
        else
        {
            last;
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

