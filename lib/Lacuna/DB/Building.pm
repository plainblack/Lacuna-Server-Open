package Lacuna::DB::Building;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->add_attributes(
    date_created    => { isa => 'DateTime' },
    body_id         => { isa => 'Str' },
    x               => { isa => 'Int' },
    y               => { isa => 'Int' },
    level           => { isa => 'Int' },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body', 'body_id');

has name => (
    is      => 'ro',
    default => 'Building',
);

has image => (
    is      => 'ro',
    default => undef,
);

has energy_to_build => (
    is      => 'ro',
    default => 0,
);

has food_to_build => (
    is      => 'ro',
    default => 0,
);

has minerals_to_build => (
    is      => 'ro',
    default => 0,
);

has water_to_build => (
    is      => 'ro',
    default => 0,
);

has waste_to_build => (
    is      => 'ro',
    default => 0,
);

has happiness_production => (
    is      => 'ro',
    default => 0,
);

has energy_production => (
    is      => 'ro',
    default => 0,
);

has water_production => (
    is      => 'ro',
    default => 0,
);

has waste_production => (
    is      => 'ro',
    default => 0,
);

has food_production => (
    is      => 'ro',
    default => 0,
);

has food_prodced => (
    is      => 'ro',
    default => undef,
);

has mineral_production => (
    is      => 'ro',
    default => 0,
);

has water_storage => (
    is      => 'ro',
    default => 0,
);

has energy_storage => (
    is      => 'ro',
    default => 0,
);

has food_storage => (
    is      => 'ro',
    default => 0,
);

has mineral_storage => (
    is      => 'ro',
    default => 0,
);

has waste_storage => (
    is      => 'ro',
    default => 0,
);

no Moose;
__PACKAGE__->meta->make_immutable;
