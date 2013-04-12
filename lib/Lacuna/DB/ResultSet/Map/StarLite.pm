package Lacuna::DB::ResultSet::Map::StarLite;

use Moose;
use utf8;
no warnings qw(uninitialized);

extends 'Lacuna::DB::ResultSet';

# Create a starmap
#
sub get_star_map {
    my ($self, $alliance_id, $empire_id, $left, $right, $bottom, $top) = @_;

    my $rs = $self->search({}, { bind => [$alliance_id, $empire_id, $left, $right, $bottom, $top] });

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
            };

            $star_id = $row->star_id;
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
            };
            push @{$star->{bodies}}, $body;
        }
    }
    push @out, $star;

    return {
        stars => \@out,
    };
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

