use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna;

use Getopt::Long;
use utf8;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);

# This script is a one-off script which calculates the result of all Stations
# which have an influence on each star and updates it with the alliance and
# influence.
#
# It is not intended that it is run in production, there should be a script
# which will update the stars and the influence table automatically whenever
# there is a significant change to a SS
#

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

out('Seizing Stars');

my $dbh = $db->resultset('Influence')->result_source->storage->dbh;

out("dbh = $dbh");

# For each star which has been seized
#
# select distinct(star_id) from influence;
#
# (star_id = 4)
# Get the alliance with the most influence
#
# select alliance_id, sum(influence) as best from influence where star_id=4 group by alliance_id order by best desc limit 1;
# (alliance_id=978, best=5)
#
# Calculate the net influence by that alliance
#
# select 5 - sum(influence) from influence where star_id=4 and alliance_id != 978;
#
# (will return NULL if there are no more alliances)
#
# Set everything to unseized
$db->resultset('Map::Star')->search()->update({
    alliance_id     => undef,
    influence  => 0,
});

my $sth = $dbh->prepare('select star_id,count(distinct(alliance_id)) from influence group by star_id');
$sth->execute();
while (my $star_ref = $sth->fetchrow_arrayref) {
    my ($star_id, $alliances) = @$star_ref;
    my $influence;
    my $alliance_id;
    if ($alliances == 1) {
        # Then one alliance has all the influence
        ($alliance_id, $influence) = $dbh->selectrow_array('select alliance_id,sum(influence) from influence where star_id=?',undef,$star_id) or die $dbh->errstr;
#        out("Only one alliance [$alliance_id] influence [$influence]");
    }
    else {
        # We need to get the alliance with the most influence
        my $alliance_strength;
        ($alliance_id, $alliance_strength) = $dbh->selectrow_array('select alliance_id,sum(influence) as best from influence where star_id=? group by alliance_id order by best desc limit 1', undef, $star_id);
#        out("Multiple alliances [$alliance_id] strength [$alliance_strength]");
        ($influence) = $dbh->selectrow_array('select ? - sum(influence) from influence where star_id=? and alliance_id != ?', undef, $alliance_strength, $star_id, $alliance_id) or die $dbh->errstr;
#        out("Final strength [$influence]");
    }
    out("Star $star_id, Alliance $alliance_id, strength $influence");

    # Record the strongest alliance, and their strength on the star
    my ($star) = $db->resultset('Map::Star')->search({
        id     => $star_id,
    });
    $star->alliance_id($alliance_id);
    $star->influence($influence);
        $star->update;
}


###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say DateTime->now, " ", $message;
    }
}


