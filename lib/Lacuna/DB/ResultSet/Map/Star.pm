package Lacuna::DB::ResultSet::Map::Star;

use Moose;
use utf8;
no warnings qw(uninitialized);
#use Lacuna;

extends 'Lacuna::DB::ResultSet';

sub recalc_control {
    my ($self) = @_;

    # first look through any stars whose influence was changed in the last 26 hours.
    my $db = Lacuna->db;
    my $dtf = $db->storage->datetime_parser;

    my $too_new = $dtf->format_datetime(DateTime->now->subtract(hours => 26));
    my $stars = $db->resultset('StationInfluence')->
        search({ oldstart => { '>' => $too_new }, }, { select => { distinct => 'star_id'}, as => 'star_id' });
    while (my $s = $stars->next)
    {
        Lacuna->db->resultset('Map::Star')->find($s->star_id)->recalc_influence;
    }

    # are there any stars still in need of recalc (e.g., for deletes)?
    $stars = $self->search({ needs_recalc => 1 }, {});
    while (my $star = $stars->next)
    {
        $star->recalc_influence;
    }
}

1;

