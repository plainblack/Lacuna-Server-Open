package Lacuna::DB::Result::Map::Body::Planet::Station;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';
use Lacuna::Util qw(randint);

use constant image => 'station';
__PACKAGE__->has_many('propositions','Lacuna::DB::Result::Propositions','station_id');

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

sub has_room_in_build_queue {
    return 1;   
}

before sanitize => sub {
    my $self = shift;
    $self->propositions->delete_all;
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
        my $building = $self->get_building_of_class('Lacuna::DB::Result::Building::StationCommand');
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

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

