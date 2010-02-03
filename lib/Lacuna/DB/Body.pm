package Lacuna::DB::Body;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util;
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use List::Util qw(shuffle);

__PACKAGE__->set_domain_name('body');
__PACKAGE__->add_attributes(
    name            => { isa => 'Str', 
        trigger => sub {
            my ($self, $new, $old) = @_;
            $self->cname(Lacuna::Util::cname($new));
        },
    },
    cname           => { isa => 'Str' },
    star_id         => { isa => 'Str' },
    orbit           => { isa => 'Int' },
    x               => { isa => 'Int' }, # indexed here to speed up
    y               => { isa => 'Int' }, # searching of planets based
    z               => { isa => 'Int' }, # on stor location
    class           => { isa => 'Str' },
);

__PACKAGE__->belongs_to('star', 'Lacuna::DB::Star', 'star_id');
__PACKAGE__->has_many('regular_buildings','Lacuna::DB::Building','body_id');
__PACKAGE__->has_many('food_buildings','Lacuna::DB::Building::Food','body_id');
__PACKAGE__->has_many('water_buildings','Lacuna::DB::Building::Water','body_id');
__PACKAGE__->has_many('waste_buildings','Lacuna::DB::Building::Waste','body_id');
__PACKAGE__->has_many('ore_buildings','Lacuna::DB::Building::Ore','body_id');
__PACKAGE__->has_many('energy_buildings','Lacuna::DB::Building::Energy','body_id');
__PACKAGE__->has_many('permanent_buildings','Lacuna::DB::Building::Permanent','body_id');
__PACKAGE__->recast_using('class');

has image => (
    is      => 'ro',
    default => undef,
);

has minerals => (
    is      => 'ro',
    default => sub { { } },
);

has water => (
    is      => 'ro',
    default => 0,
);

sub recalc_stats { } # interface

sub buildings {
    my $self = shift;
    return (
        $self->regular_buildings,
        $self->food_buildings,
        $self->water_buildings,
        $self->energy_buildings,
        $self->ore_buildings,
        $self->waste_buildings,
        $self->permanent_buildings,
        );
}

sub is_space_free {
    my ($self, $x, $y) = @_;
    my $db = $self->simpledb;
    foreach my $domain (qw(building energy water food waste ore permanent)) {
        my $count = $db->domain($domain)->count({
            body_id => $self->id,
            x       => $x,
            y       => $y,
        });
        return 0 if $count > 0;
    }
    return 1;
}

sub spend_ore {
    my ($self, $value) = @_;
    foreach my $type (shuffle ORE_TYPES) {
        my $method = $type."_stored";
        my $stored = $self->method;
        if ($stored > $value) {
            $self->method($stored - $value);
            last;
        }
        else {
            $value -= $stored;
            $self->method(0);
        }
    }
}

sub spend_food {
    my ($self, $value) = @_;
    foreach my $type (shuffle FOOD_TYPES) {
        my $method = $type."_stored";
        my $stored = $self->method;
        if ($stored > $value) {
            $self->method($stored - $value);
            last;
        }
        else {
            $value -= $stored;
            $self->method(0);
        }
    }
}

sub add_energy {
    my ($self, $value) = @_;
    my $store = $self->energy_stored + $value;
    my $storage = $self->energy_storage;
    $self->energy_stored( ($store < $storage) ? $store : $storage );
}

sub spend_energy {
    my ($self, $value) = @_;
    $self->energy_stored( $self->energy_stored - $value );
}

sub add_water {
    my ($self, $value) = @_;
    my $store = $self->water_stored + $value;
    my $storage = $self->water_storage;
    $self->water_stored( ($store < $storage) ? $store : $storage );
}

sub spend_water {
    my ($self, $value) = @_;
    $self->water_stored( $self->water_stored - $value );
}

sub add_happiness {
    my ($self, $value) = @_;
    $self->happiness( $self->happiness + $value );
}

sub spend_happiness {
    my ($self, $value) = @_;
    $self->happiness( $self->happiness - $value );
}

sub add_waste {
    my ($self, $value) = @_;
    my $store = $self->waste_stored + $value;
    my $storage = $self->waste_storage;
    $self->waste_stored( ($store < $storage) ? $store : $storage );
}

sub spend_waste {
    my ($self, $value) = @_;
    $self->waste_stored( $self->waste_stored - $value );
}


no Moose;
__PACKAGE__->meta->make_immutable;
