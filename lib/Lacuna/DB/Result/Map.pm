package Lacuna::DB::Result::Map;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('noexist_map');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    x                       => { data_type => 'int', size => 11, default_value => 0 },
    y                       => { data_type => 'int', size => 11, default_value => 0 },
    zone                    => { data_type => 'varchar', size => 16, is_nullable => 0 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_x_y', fields => ['x','y']);
    $sqlt_table->add_index(name => 'idx_zone', fields => ['zone']);
    $sqlt_table->add_index(name => 'idx_name', fields => ['name']);
}

has 'map_size' => (
    is      => 'ro',
    default => sub {return Lacuna->config->get('map_size')},
    lazy    => 1,
);

sub calculate_distance_to_xy {
    my ($self, $x, $y) = @_;

    my $x_dist = abs($self->x - $x);
    my $y_dist = abs($self->y - $y);
    $x_dist = $x_dist > $self->map_width / 2 ? abs($x_dist - $self->map_width) : $x_dist;
    $y_dist = $y_dist > $self->map_height / 2 ? abs($y_dist - $self->map_height) : $y_dist;
    return sqrt($x_dist**2 + $y_dist**2) * 100;
}

# distance from object to target. Allows for 'wrap-around' nature of the map
# where distance can never be greater than half the width,height of the map.
#
sub calculate_distance_to_target {
    my ($self, $target) = @_;
    return $self->calculate_distance_to_xy($target->x, $target->i);
}

use constant zone_size => 250;

sub map_width {
    my ($self) = @_;
    return $self->map_size->{x}[1] - $self->map_size->{x}[0];
}

sub map_height {
    my ($self) = @_;
    return $self->map_size->{y}[1] - $self->map_size->{y}[0];
}

sub zones_wide {
    my ($self) = @_;
    return $self->map_width / zone_size;
}

sub zones_high {
    my ($self) = @_;
    return $self->map_height / zone_size;
}

sub adjacent_zones {
    my ($self) = @_;

    my ($x,$y) = $self->parse_zone_into_zone_coords;
    my $zone_deltas = [
        {x => 1, y => 0},
        {x => 1, y => 1},
        {x => 1, y => -1},
        {x => 0, y => 1},
        {x => 0, y => -1},
        {x => -1, y => 0},
        {x => -1, y => 1},
        {x => -1, y => -1},
    ];
    my @zones;
    for my $delta (@$zone_deltas) {
        my $p = ($x + $delta->{x}) % $self->zones_wide;
        my $q = ($y + $delta->{y}) % $self->zones_high;
        push @zones, $self->format_zone_coords_into_zone($p, $q);
    }
    return @zones;
}

sub parse_zone_into_zone_coords {
    my ($self) = @_;
    return split('\|', $self->zone);
}

sub format_zone_coords_into_zone {
    my ($self, $x, $y) = @_;
    return join '|', $x, $y;
}

sub set_zone_from_xy {
    my ($self) = @_;
    $self->zone($self->format_zone_from_xy);
    return $self;
}

sub format_zone_from_xy {
    my ($self) = @_;
    return $self->format_zone_coords_into_zone(
        $self->determine_zone_coord_from_xy_coord($self->x, $self->y)
        );
}
#
# 0     to  249    = 0
# 250   to  499    = 1
# -250  to  -1     = -1
# -1500 to -1249   = -6
# 1250  to 1499    = 5
#
sub determine_zone_coord_from_xy_coord {
    my ($self, $coord) = @_;

    my $p = int(($coord - $self->map_size->{x}[0]) / zone_size) - int((0 - $self->map_size->{x}[0]) / zone_size); 
    my $q = int(($coord - $self->map_size->{y}[0]) / zone_size) - int((0 - $self->map_size->{y}[0]) / zone_size);
    return ($p, $q);
}

sub in_neutral_area {
    my ($self) = shift;

    my $na_param = Lacuna->config->get('neutral_area');
    if ($na_param) {
        return 0 unless $na_param->{active};
        my $zone = $self->zone;
        my $x    = $self->x;
        my $y    = $self->y;
        if ($na_param->{zone} and $na_param->{coord}) {
            # Needs to be in both to qualify as in         
            my $in_zone = 0;
            for my $z_test (@{$na_param->{zone_list}}) {
                $in_zone = 1 if ($zone eq $z_test);
            }
            return 0 unless $in_zone;
            if ($x >= $na_param->{x}[0] and
                $x <= $na_param->{x}[1] and
                $y >= $na_param->{y}[0] and
                $y <= $na_param->{y}[1]) {
                return 1;
            }
        }
        elsif ($na_param->{zone}) {
            for my $z_test (@{$na_param->{zone_list}}) {
                return 1 if ($zone eq $z_test);
            }
        }
        elsif ($na_param->{coord}) {
            if ($x >= $na_param->{x}[0] and
                $x <= $na_param->{x}[1] and
                $y >= $na_param->{y}[0] and
                $y <= $na_param->{y}[1]) {
                return 1;
            }
        }
    }
    return 0;
}

sub in_starter_zone {
    my ($self) = shift;

    my $sz_param = Lacuna->config->get('starter_zone');
    if ($sz_param) {
        return 0 unless $sz_param->{active};
        my $zone = $self->zone;
        my $x    = $self->x;
        my $y    = $self->y;
        if ($sz_param->{zone} and $sz_param->{coord}) {
# Needs to be in both to qualify as in         
            my $in_zone = 0;
            for my $z_test (@{$sz_param->{zone_list}}) {
                $in_zone = 1 if ($zone eq $z_test);
            }
            return 0 unless $in_zone;
            if ($x >= $sz_param->{x}[0] and
                $x <= $sz_param->{x}[1] and
                $y >= $sz_param->{y}[0] and
                $y <= $sz_param->{y}[1]) {
                return 1;
            }
        }
        elsif ($sz_param->{zone}) {
            for my $z_test (@{$sz_param->{zone_list}}) {
                return 1 if ($zone eq $z_test);
            }
        }
        elsif ($sz_param->{coord}) {
            if ($x >= $sz_param->{x}[0] and
                $x <= $sz_param->{x}[1] and
                $y >= $sz_param->{y}[0] and
                $y <= $sz_param->{y}[1]) {
                return 1;
            }
        }
    }
    return 0;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
