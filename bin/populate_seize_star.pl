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

out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

out('Ticking Space Stations');

$db->resultset('Influence')->delete;


my $stations_rs = $db->resultset('Map::Body')->search({
    class => 'Lacuna::DB::Result::Map::Body::Planet::Station'
});
while (my $station = $stations_rs->next) {
#    out('Seizing at  '.$station->name.' : '.$station->id.' - influence='.$station->total_influence.' range = '.$station->range_of_influence);

    # The 'influence' imposed on a star by one Space Station is calculated thus.
    #
    # RANGE * TOTAL_INFLUENCE * 75 / dist^2 / 1000
    #
    # RANGE = The range of the Interstellar Broacast System
    # TOTAL_INFLUENCE = Combined influence of Art, Culinary, Opera and Police
    # dist = distance from the SS to the star
    #
    # A single SS acting alone can seize a star if it's influence exceeds 50 (percent) on the star
    # Influence diminishes by the formula, the greater the distance.
    # Typically a SS with all level 25 modules can seize all stars within a radius of 6100, which is about 150 stars
    # (better than currently by 50%)
    #
    # However, stars at a range greater than 6100 will not be seized (currently this level of SS can seize out to distance 25000
    # Although past the distance of 6100 stars are not seized, they are still influenced, so multiple SS acting together
    # could seize more stars by combining their influence until it exceeds 50%
    #
    # Conversely, SS from other alliances will diminish the influence of the strongest alliance.
    #

    my $star_units  = $station->range_of_influence / 100;
    my $influence   = $station->total_influence;
    my $minus_x     = 0 - $station->x;
    my $minus_y     = 0 - $station->y;
    my $numerator   = 


    # All stars in range of the SS
    my $stars_rs = $db->resultset('Map::Star')->search({
        -and => [
            \[ "ceil(pow(pow(me.x + $minus_x, 2) + pow(me.y + $minus_y, 2), 0.5)) < $star_units" ],
        ]
    },{
        '+select' => [
            { ceil => \"pow(pow(me.x + $minus_x,2) + pow(me.y + $minus_y,2), 0.5)", '-as' => 'distance' },
        ],
        '+as' => [
            'distance',
        ],
    });
    my $seized = 0;
    while (my $star = $stars_rs->next) {
        my $star_distance = $star->get_column('distance');
        my $star_influence = int($star_units * $influence * 75 / ($star_distance * $star_distance) / 10);

        $star_influence = 0 if $star_influence < 5;

#        out('Processing star '.$star->name." at distance $star_distance and influence $star_influence") if $star_influence > 0;
        if ($star_influence > 0) {
            $db->resultset('Influence')->create({
                station_id      => $station->id,
                star_id         => $star->id,
                alliance_id     => $station->alliance_id,
                influence       => $star_influence,
            });
            if ($star_influence >= 50) {
                $seized++;
            }
        }
    }
    my $old_count = $db->resultset('Map::Star')->search({
        station_id => $station->id,
    })->count;
    
    out("Previous\t$old_count\tNow\t$seized\t".$station->name);
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say DateTime->now, " ", $message;
    }
}


