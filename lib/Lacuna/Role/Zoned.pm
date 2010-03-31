package Lacuna::Role::Zoned;

use Moose::Role;

requires 'zone';

use constant zone_size => 10;

sub adjacent_zones {
    my ($self) = @_;
    my ($x,$y,$z) = $self->parse_zone_into_zone_coords;
    my @zones;
    push @zones, $self->format_zone_coords_into_zone($x + 1, $y, $z);
    push @zones, $self->format_zone_coords_into_zone($x - 1, $y, $z);
    push @zones, $self->format_zone_coords_into_zone($x, $y + 1, $z);
    push @zones, $self->format_zone_coords_into_zone($x, $y - 1, $z);
    push @zones, $self->format_zone_coords_into_zone($x, $y, $z + 1);
    push @zones, $self->format_zone_coords_into_zone($x, $y, $z - 1);
    return @zones;
}

sub parse_zone_into_zone_coords {
    my ($self) = @_;
    return split '|', $self->zone;
}

sub format_zone_coords_into_zone {
    my ($self, $x, $y, $z) = @_;
    return join '|', $x, $y, $z;
}

sub set_zone_from_xyz {
    my ($self) = @_;
    $self->zone($self->format_zone_from_xyz);
}

sub format_zone_from_xyz {
    my ($self) = @_;
    return $self->format_zone_coords_into_zone(
        $self->determine_zone_coord_from_xyz_coord($self->x),
        $self->determine_zone_coord_from_xyz_coord($self->y),
        $self->determine_zone_coord_from_xyz_coord($self->z)
        );
}

sub determine_zone_coord_from_xyz_coord {
    my ($self, $coord) = @_;
    return int($coord / zone_size);
}

1;
