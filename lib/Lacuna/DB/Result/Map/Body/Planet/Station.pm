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
        class       => 'Lacuna::DB::Result::Map::Body::Asteroid::A'.randint(1,21),
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
            $influence += $building->level;
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
        $range = $ibs->level * 1000;
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


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

