package Lacuna::DB::Result::Map::Body::Planet::Station;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';
use Lacuna::Util qw(randint);

use constant image => 'station';
__PACKAGE__->has_many('propositions','Lacuna::DB::Result::Propositions','station_id');
__PACKAGE__->has_many('laws','Lacuna::DB::Result::Laws','station_id');
__PACKAGE__->has_many('stars','Lacuna::DB::Result::Map::Star','station_id');

has parliament => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $parliament = $self->get_building_of_class('Lacuna::DB::Result::Building::Module::Parliament');
        if (defined $parliament) {
            $parliament->body($self);
        }
        return $parliament;
    },
);

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
    default => sub {
        my $self = shift;
        my $building = $self->get_building_of_class('Lacuna::DB::Result::Building::Module::StationCommand');
        return undef unless defined $building;
        $building->body($self);
        return $building;
    },
);

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
    my $type = '';
    $type = 'star' if (ref $target eq 'Lacuna::DB::Result::Map::Star');
    $type = 'body' if (ref $target =~ /Lacuna::DB::Result::Map::Body/);
    unless ($type) {
        confess [1009, 'Invalid target'];
    }
    my $class = ( $type eq 'star' ) ? 'Lacuna::DB::Result::Map::Star' : 'Lacuna::DB::Result::Map::Body';
    my $search = Lacuna->db->resultset($class);
    my $find = $search->find($target->id);
    unless (defined $find) {
        confess [1009, 'Invalid target'];
    }
    if ($type eq 'star' && $find->station_id != $self->id) {
        confess [1009, 'Target is not in the station\'s jurisdiction.'];
    }
    elsif ($find->star->station_id != $self->id) {
        confess [1009, 'Target is not in the station\'s jurisdiction.'];
    }
}

has total_influence => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->buildings
            ->search({ class => { in => ['Lacuna::DB::Result::Building::Module::OperaHouse','Lacuna::DB::Result::Building::Module::CulinaryInstitute','Lacuna::DB::Result::Building::Module::ArtMuseum'] }})
            ->get_column('level')
            ->sum;
    },
);

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
    default => sub {
        my $self = shift;
        return $self->buildings
            ->search({ class => 'Lacuna::DB::Result::Building::Module::IBS'})
            ->get_column('level')
            ->sum
            * 1000;
    },
);

sub in_range_of_influence {
    my ($self, $star) = @_;
    if ($self->calculate_distance_to_target($star) > $self->range_of_influence) {
        confess [1009, 'That star is not in the station\'s range of influence.'];
    }
    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

