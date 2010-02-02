package Lacuna::DB::Building;

use Moose;
extends 'SimpleDB::Class::Item';

use constant INFLATION => 1.8847;
use constant GROWTH => 1.292;
use constant FOOD_TYPES => (qw(lapis potato apple root corn cider wheat bread soup chip pie pancake milk meal algae syrup fungus burger shake beetle));
use constant ORE_TYPES => (qw(rutile chromite chalcopyrite galena gold uraninite bauxite limonite halite gypsum trona kerogen petroleum anthracite sulfate zircon monazite fluorite beryl magnetite));



__PACKAGE__->add_attributes(
    date_created    => { isa => 'DateTime' },
    body_id         => { isa => 'Str' },
    empire_id       => { isa => 'Str' },
    x               => { isa => 'Int' },
    y               => { isa => 'Int' },
    level           => { isa => 'Int' },
    class           => { isa => 'Str' },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body', 'body_id');
__PACKAGE__->recast_using('class');

has name => (
    is      => 'ro',
    default => 'Building',
);

has image => (
    is      => 'ro',
    default => undef,
);

has time_to_build => (
    is      => 'ro',
    default => '60',
);

has energy_to_build => (
    is      => 'ro',
    default => 0,
);

has food_to_build => (
    is      => 'ro',
    default => 0,
);

has ore_to_build => (
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

has happiness_consumption => (
    is      => 'ro',
    default => 0,
);

has energy_consumption => (
    is      => 'ro',
    default => 0,
);

has water_consumption => (
    is      => 'ro',
    default => 0,
);

has waste_consumption => (
    is      => 'ro',
    default => 0,
);

has food_consumption => (
    is      => 'ro',
    default => 0,
);

has ore_consumption => (
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

has beetle_production => (
    is      => 'ro',
    default => 0,
);

has shake_production => (
    is      => 'ro',
    default => 0,
);

has burger_production => (
    is      => 'ro',
    default => 0,
);

has fungus_production => (
    is      => 'ro',
    default => 0,
);

has syrup_production => (
    is      => 'ro',
    default => 0,
);

has algae_production => (
    is      => 'ro',
    default => 0,
);

has meal_production => (
    is      => 'ro',
    default => 0,
);

has milk_production => (
    is      => 'ro',
    default => 0,
);

has pancake_production => (
    is      => 'ro',
    default => 0,
);

has pie_production => (
    is      => 'ro',
    default => 0,
);

has chip_production => (
    is      => 'ro',
    default => 0,
);

has soup_production => (
    is      => 'ro',
    default => 0,
);

has bread_production => (
    is      => 'ro',
    default => 0,
);

has wheat_production => (
    is      => 'ro',
    default => 0,
);

has cider_production => (
    is      => 'ro',
    default => 0,
);

has corn_production => (
    is      => 'ro',
    default => 0,
);

has root_production => (
    is      => 'ro',
    default => 0,
);

has apple_production => (
    is      => 'ro',
    default => 0,
);

has lapis_production => (
    is      => 'ro',
    default => 0,
);

has potato_production => (
    is      => 'ro',
    default => 0,
);

has ore_production => (
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

has ore_storage => (
    is      => 'ro',
    default => 0,
);

has waste_storage => (
    is      => 'ro',
    default => 0,
);


sub food_per_tick {
    my ($self) = @_;
    return $self->food_production;
}

sub energy_per_tick {
    my ($self) = @_;
    return $self->energy_production;
}

sub ore_per_tick {
    my ($self) = @_;
    return $self->ore_production;
}

sub water_per_tick {
    my ($self) = @_;
    return $self->water_production;
}

sub waste_per_tick {
    my ($self) = @_;
    return $self->waste_production;
}

sub food_to_upgrade {
    my ($self) = @_;
    my $next_level = $self->level + 1;
    return $self->food_to_build * (INFLATION ** ($next_level - 1));
}

sub energy_to_upgrade {
    my ($self) = @_;
    my $next_level = $self->level + 1;
    return $self->energy_to_build * $next_level;
}

sub ore_to_upgrade {
    my ($self) = @_;
    my $next_level = $self->level + 1;
    return $self->ore_to_build * $next_level;
}

sub water_to_upgrade {
    my ($self) = @_;
    my $next_level = $self->level + 1;
    return $self->water_to_build * $next_level;
}

sub waste_to_upgrade {
    my ($self) = @_;
    my $next_level = $self->level + 1;
    return $self->waste_to_build * $next_level;
}

sub food_production_delta_after_upgrade {
    my ($self) = @_;
    my $next_level = $self->level + 1;
    return $self->waste_to_build * $next_level;
}

no Moose;
__PACKAGE__->meta->make_immutable;
