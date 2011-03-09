package Lacuna::DB::Result::Building::Module;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

sub image_level {
    my $self = shift;
    return $self->image;
}

use constant energy_consumption => 200;
use constant water_consumption => 100;
use constant food_consumption => 100;
use constant ore_consumption => 100;
use constant energy_to_build => 500;
use constant food_to_build => 100;
use constant ore_to_build => 500;
use constant water_to_build => 150;

around spend_efficiency => sub {
    my ($orig, $self, $amount) = @_;
    if ($self->efficiency <= $amount) {
        if ($self->level <= 1 && eval{$self->can_demolish}) {
            $self->demolish;
        }
        elsif ($self->level > 1 && eval{$self->can_downgrade}) {
            $self->downgrade;
        }
        else {
            $orig->($self, $amount);
        }
    }
    else {
        $orig->($self, $amount);
    }
    return $self;
};

sub cost_to_upgrade {
    return {
        food    => 0,
        ore     => 0,
        water   => 0,
        energy  => 0,
        waste   => 0,
        time    => 60,
    };
}

around can_upgrade => sub {
    my ($orig, $self, $cost, $from_parliament) = @_;
    if ($from_parliament) {
        $orig->($self, $cost);
    }
    else {
        confess [1010, 'Space station modules can only be upgraded by an act of Parliament.'];
    }
};

around can_downgrade => sub {
    my ($orig, $self, $cost, $from_parliament) = @_;
    if ($from_parliament) {
        $orig->($self, $cost);
    }
    else {
        confess [1010, 'Space station modules can only be downgraded by an act of Parliament.'];
    }
};

around can_demolish => sub {
    my ($orig, $self, $cost, $from_parliament) = @_;
    if ($from_parliament) {
        $orig->($self, $cost);
    }
    else {
        confess [1010, 'Space station modules can only be demolished by an act of Parliament.'];
    }
};

around can_build => sub {
    my ($orig, $self, $cost, $from_parliament) = @_;
    if ($from_parliament) {
        $orig->($self, $cost);
    }
    else {
        confess [1010, 'Space station modules can only be built by an act of Parliament.'];
    }
};

around can_repair => sub {
    my ($orig, $self, $cost, $from_parliament) = @_;
    if ($from_parliament) {
        $orig->($self, $cost);
    }
    else {
        confess [1010, 'Space station modules can only be repaired by an act of Parliament.'];
    }
};

sub can_build_on {
    my $self = shift;
    if ($self->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        confess [1009, 'Can only be built on space stations.'];
    }
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
