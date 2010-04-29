package Lacuna::Role::Shippable;

use Moose::Role;
requires 'empire';
requires 'body';

use constant cargo_ship_base => 2000;
use constant smuggler_ship_base => 1200;

has trade_ministry => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->body->get_building_of_class('Lacuna::DB::Building::Trade');
    },
);

has hold_size_bonus => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return (100 + ($self->empire->species->trade_affinity * 25) + ($self->trade_ministry->level * 30)) / 100;
    },
);

has cargo_ship_hold_size => (
    is      => 1,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return sprintf('%.0f', $self->cargo_ship_base * $self->hold_size_bonus);
    }
);

has smuggler_ship_hold_size => (
    is      => 1,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return sprintf('%.0f', $self->cargo_ship_base * $self->hold_size_bonus);
    }
);


1;
