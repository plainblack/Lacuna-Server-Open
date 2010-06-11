package Lacuna::DB::Result::Map;

use Moose;
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


sub calculate_distance_to_target {
    my ($self, $target) = @_;
    return sqrt(abs($self->x - $target->x)**2 + abs($self->y - $target->y)**2) * 100;
}

use constant zone_size => 250;

sub adjacent_zones {
    my ($self) = @_;
    my ($x,$y) = $self->parse_zone_into_zone_coords;
    my @zones;
    push @zones, $self->format_zone_coords_into_zone($x + 1, $y);
    push @zones, $self->format_zone_coords_into_zone($x - 1, $y);
    push @zones, $self->format_zone_coords_into_zone($x, $y + 1);
    push @zones, $self->format_zone_coords_into_zone($x, $y - 1);
    push @zones, $self->format_zone_coords_into_zone($x - 1, $y - 1);
    push @zones, $self->format_zone_coords_into_zone($x + 1, $y + 1);
    push @zones, $self->format_zone_coords_into_zone($x - 1, $y + 1);
    push @zones, $self->format_zone_coords_into_zone($x + 1, $y - 1);
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
        $self->determine_zone_coord_from_xy_coord($self->x),
        $self->determine_zone_coord_from_xy_coord($self->y),
        );
}

sub determine_zone_coord_from_xy_coord {
    my ($self, $coord) = @_;
    return int($coord / zone_size);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
