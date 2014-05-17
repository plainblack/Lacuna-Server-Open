package Lacuna::DB::ResultSet::Map::Star;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Lacuna;

extends 'Lacuna::DB::ResultSet';

# Recalc all stars that are so set
#
sub recalc_all {
    my ($self) = @_;

    my $db = Lacuna->db;
    my $dbh = $self->result_source->storage->dbh;

    my $sth = $dbh->prepare('select star_id,count(distinct(alliance_id)) from seize_star group by star_id');
    $sth->execute();
    while (my $star_ref = $sth->fetchrow_arrayref) {
        my ($star_id, $alliances) = @$star_ref;
        my $influence;
        my $alliance_id;
        if ($alliances == 1) {
            # Then one alliance has all the influence
            ($alliance_id, $influence) = $dbh->selectrow_array('select alliance_id,sum(influence) from seize_star where star_id=?',undef,$star_id) or die $dbh->errstr;
        }
        else {
            # We need to get the alliance with the most influence
            my $alliance_strength;
            ($alliance_id, $alliance_strength) = $dbh->selectrow_array('select alliance_id,sum(influence) as best from seize_star where star_id=? group by alliance_id order by best desc limit 1', undef, $star_id);
            ($influence) = $dbh->selectrow_array('select ? - sum(influence) from seize_star where star_id=? and alliance_id != ?', undef, $alliance_strength, $star_id, $alliance_id) or die $dbh->errstr;
        }

        # Record the strongest alliance, and their strength on the star
        my ($star) = $db->resultset('Map::Star')->search({
            id     => $star_id,
        });
        $star->alliance_id($alliance_id);
        $star->influence($influence);
        $star->update;
    }
}
 
no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

