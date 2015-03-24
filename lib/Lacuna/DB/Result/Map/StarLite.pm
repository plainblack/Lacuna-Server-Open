package Lacuna::DB::Result::Map::StarLite;

use Moose;
use utf8;
no warnings qw(uninitialized);

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('TimeStamp', 'InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

# This is a 'lite' version of L::D::R::Map::Star which is much more efficient
# in returning data for the starmap

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('star_lite');

__PACKAGE__->add_columns(
    star_id                 => { data_type => 'int', size => 11},
    star_name               => { data_type => 'varchar', size => 30, is_nullable => 0 },
    star_color              => { data_type => 'varchar', size => 8, is_nullable => 0 },
    star_x                  => { data_type => 'int', size => 11, default_value => 0 },
    star_y                  => { data_type => 'int', size => 11, default_value => 0 },
    star_zone               => { data_type => 'varchar', size => 16, is_nullable => 0 },
    station_id              => { data_type => 'int', size => 11}, 
    influence               => { data_type => 'int', size => 11}, 
    body_id                 => { data_type => 'int', size => 11},
    body_name               => { data_type => 'varchar', size => 30, is_nullable => 0 },
    body_orbit              => { data_type => 'int', default_value => 0 },
    body_x                  => { data_type => 'int', size => 11, default_value => 0 },
    body_y                  => { data_type => 'int', size => 11, default_value => 0 },
    body_class              => { data_type => 'varchar', size => 255, is_nullable => 0 },
    body_size               => { data_type => 'int', default_value => 0 },
    empire_id               => { data_type => 'int', size => 11},
    empire_name             => { data_type => 'varchar', size => 30, is_nullable => 0 },
    empire_is_isolationist  => { data_type => 'tinyint', default_value => 1 },
    empire_alliance_id      => { data_type => 'int', size => 11 },
    body_has_fissure        => { data_type => 'int', size => 11 },
);

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q[
    select 
        distinct(star.id) AS star_id,
        star.name AS star_name,
        star.color AS star_color,
        star.x AS star_x,
        star.y AS star_y,
        star.zone as star_zone,
        star.station_id AS station_id,
        star.influence AS influence,
        body.id AS body_id,
        body.name AS body_name,
        body.orbit AS body_orbit,
        body.x AS body_x,
        body.y AS body_y,
        body.class AS body_class,
        body.size AS body_size,
        empire.id AS empire_id,
        empire.name AS empire_name,
        empire.is_isolationist AS empire_is_isolationist,
        empire.alliance_id AS empire_alliance_id,
        building.id AS body_has_fissure
    from star
    LEFT JOIN probes
      ON star.id = probes.star_id AND (probes.alliance_id=? OR probes.empire_id=?)
    LEFT JOIN body
      ON star.id = body.star_id AND probes.id is not null
    LEFT JOIN empire
      ON body.empire_id = empire.id 
    LEFT JOIN building
      ON body.id = building.body_id 
      AND building.class='Lacuna::DB::Result::Building::Permanent::Fissure'
    WHERE star.x >= ?
    AND star.x <= ?
    AND star.y >= ?
    AND star.y <= ?
    ORDER BY star.id
]);
# bind variables are alliance_id,empire_id,left,right,bottom,top

__PACKAGE__->belongs_to('station', 'Lacuna::DB::Result::Map::Body', 'station_id');

# get the planet image name 
# NOTE: This is not good, since image name generation is now duplicated.
# to 'fix' this would need significant refactoring of the way body images and
# types are calculated
#
sub body_image {
    my ($self) = @_;

    my ($image) = $self->body_class =~ m/:(\w+)$/;
    $image =~ s/A21/debris1/;
    $image =~ s/G/pg/;
    $image =~ s/P/p/;
    $image =~ s/A/a/;
    $image =~ s/Station/station/;
    return $image.'-'.$self->body_orbit;
}

sub body_type {
    my ($self) = @_;

    return 'gas giant'      if $self->body_class =~ m/GasGiant/;
    return 'asteroid'       if $self->body_class =~ m/Asteroid/;
    return 'space station'  if $self->body_class =~ m/Station/;

    return 'habitable planet';
}

sub star_zone {
    my ($self) = @_;

    return join '|', $self->star_x, $self->star_y;
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
