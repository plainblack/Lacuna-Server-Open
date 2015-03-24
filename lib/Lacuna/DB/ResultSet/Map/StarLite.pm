package Lacuna::DB::ResultSet::Map::StarLite;

use Moose;
use utf8;
no warnings qw(uninitialized);
#use Lacuna;

extends 'Lacuna::DB::ResultSet';

# Create a starmap
#
sub get_star_map {
    my ($self, $alliance_id, $empire_id, $left, $right, $bottom, $top) = @_;

    my $cache = Lacuna->cache;
    
    my $rs = $self->search({}, { 
        bind        => [$alliance_id, $empire_id, $left, $right, $bottom, $top],
    });

    my $star_id=0;
    my $star;
    my @out;
    while (my $row = $rs->next) {
        if ($row->star_id != $star_id) {
            if ($star_id) {
                push @out, $star;
            }
            $star = {
                name    => $row->star_name,
                color   => $row->star_color,
                x       => $row->star_x,
                y       => $row->star_y,
                id      => $row->star_id,
                zone    => $row->star_zone,
                influence => $row->influence,
            };

            $star_id = $row->star_id;
        }
        if (defined $row->station_id) {
            my $station = $cache->get_and_deserialize('starlite_station',$row->station_id);
            if (not $station) {
                $station = {
                    id          => $row->station->id,
                    name        => $row->station->name,
                    x           => $row->station->x,
                    y           => $row->station->y,
                    alliance    => {
                        name    => $row->station->alliance->name,
                        id      => $row->station->alliance_id,
                        image   => $row->station->alliance->image,
                    }
                };
                # set the expiry to 1hr
                $cache->set('starlite_station',$row->station_id, $station, 60 * 60);
            }
            $star->{station} = $station;
        }
        if (defined $row->body_id) {
            my $body = {
                name    => $row->body_name,
                id      => $row->body_id,
                orbit   => $row->body_orbit,
                x       => $row->body_x,
                y       => $row->body_y,
                type    => $row->body_type,
                image   => $row->body_image,
                size    => $row->body_size,
                body_has_fissure => $row->body_has_fissure ? 1 : 0,
            };
            if (defined $row->empire_id) {
                my $alignment   = 'hostile';
                $alignment      = 'ally' if $row->empire_alliance_id == $alliance_id;
                $alignment      = 'self' if $row->empire_id == $empire_id;
                $alignment .= '-isolationist' if $row->empire_is_isolationist;

                my $empire = {
                    id              => $row->empire_id,
                    name            => $row->empire_name,
                    alignment       => $alignment,
                    is_isolationist => $row->empire_is_isolationist,
                };
                $body->{empire} = $empire;
            }
            push @{$star->{bodies}}, $body;
        }
    }
    push @out, $star if defined $star;

    return {
        stars => \@out,
    };
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

