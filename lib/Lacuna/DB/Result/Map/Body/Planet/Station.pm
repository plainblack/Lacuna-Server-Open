package Lacuna::DB::Result::Map::Body::Planet::Station;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';
use Lacuna::Util qw(randint);
use Data::Dumper;

use constant image => 'station';
__PACKAGE__->has_many('propositions','Lacuna::DB::Result::Propositions','station_id');
__PACKAGE__->has_many('laws','Lacuna::DB::Result::Laws','station_id');
__PACKAGE__->has_many('seize_stars', 'Lacuna::DB::Result::SeizeStar','station_id');

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
            total => $self->total_influence,
            range => $self->range_of_influence,
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

    # All buildings should be demolished, so no influence.
    #  
    $self->recalc_influence;

    $self->update({
        size            => randint(1,10),
        class           => 'Lacuna::DB::Result::Map::Body::Asteroid::A'.randint(1,21),
        alliance_id     => undef,
        seize_strength  => 0,
    });
};

after recalc_stats => sub {
    my $self = shift;
    $self->recalc_influence;
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
        my $star = Lacuna->db->resultset('Map::Star')->find($target->id);
        unless (defined $star) {
            confess [1009, 'Invalid star'];
        }
        unless ($star->alliance_id == $self->alliance_id) {
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
            $influence += ($building->level * $building->efficiency) / 100;
        }
    }
    return $influence;
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
        $range = $ibs->level * $ibs->efficiency * 1000 / 100;
    }
    return $range;
}

sub in_range_of_influence {
    my ($self, $star) = @_;
    if ($self->calculate_distance_to_target($star) > $self->range_of_influence) {
        return;
    }
    return 1;
}

# Recalculate the influence of this station, this needs to be done when anything
# affecting the SS influence takes place, examples include.
#   Moving the SS
#   Building/Upgrading/Downgrading a module
#   Destroying it
#   Modules changing efficiency
#
# We are using 'raw' SQL here since it is far more efficient than processing records
# one-by-one using DBIx::Class
#
sub recalc_influence {
    my ($self) = @_;

    my ($ibs) = grep {$_->class eq 'Lacuna::DB::Result::Building::Module::IBS'} @{$self->building_cache};
    my $ibs_level = defined $ibs ? $ibs->level : 0;
    
    # Mark all stars as 'recalc' currently linked to this station via the seize_star table
    #
    my $dbh = $self->result_source->storage->dbh;
    my $sth_star = $dbh->prepare('update star join seize_star on star.id = seize_star.star_id set recalc=1 where seize_star.station_id=?');
    $sth_star->execute($self->id);


    # Delete all the existing seize_star records
    #
    my $sth = $dbh->prepare('delete from seize_star where station_id=?');
    $sth->execute($self->id);


    # Recalculate all the new seize_star records
    #
    if ($ibs_level and $self->total_influence > 0) {
        my $sql = <<END_SQL;
insert into seize_star (station_id,star_id,alliance_id,seize_strength) (
  select
    ? as station_id,
    star.id as star_id,
    ? as alliance_id,
    ceil(? * ? * 7.5 / (pow(star.x - body.x, 2) + pow(star.y - body.y, 2))) as seize_strength
    from star, body
    where body.id=?
    and ceil(pow(pow(star.x - body.x, 2) + pow(star.y - body.y, 2), 0.5)) < ?
  )
;
END_SQL
        $sth = $dbh->do($sql, undef, $self->id, $self->alliance_id, $ibs_level, $self->total_influence, $self->id, $self->range_of_influence / 100);

        # Mark all the 'new' stars as 'recalc' linked to this station via the seize_star table (we can use the earlier prepared statement)
        #
        $sth_star->execute($self->id);
    }

    # Now recalculate the allegience of all such marked stars
    #    
    $self->result_source->schema->resultset('Map::Star')->recalc_all;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

