use lib '../lib';

use strict;
use warnings;

use Test::More tests => 3;
use Test::Deep;
use Test::Memory::Cycle;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna;
use TestHelper;

my $empire_name     = 'TLE Test Empire';
my $station_name    = 'TLE Test Station';

my $tester  = TestHelper->new({empire_name => $empire_name});
my $empire  = $tester->empire;
my $session = $empire->start_session({api_key => 'tester'});

my ($station) = Lacuna->db->resultset('Map::Body::Planet')->search({name => $station_name});

my $stars   = Lacuna->db->resultset('Map::Star')->search;

# get all stars in this stations jurisdiction
# give them a name we can sort by
my $stars_rs = $stars->search({ station_id => $station->id });
my $star_num = '001';
while( my $star = $stars_rs->next ) {
    diag ("Rename ".$star->name." to $station_name $star_num");
    $star->name("$station_name $star_num");
    $star->update;
    $star_num++;
}

# TODO Call get_stars_in_jurisdiction and check sort order


my $influence_spent     = $station->influence_spent;
my $influence_remaining = $station->influence_remaining;

# get unseized stars in order distance from station.
my $minus_x = 0 - $station->x;
my $minus_y = 0 - $station->y;

my $closest = Lacuna->db->resultset('Map::Star')->search({
    station_id => undef,
},{
    '+select' => [
        { ceil => \"pow(pow(me.x + $minus_x,2) + pow(me.y + $minus_y,2), 0.5)", '-as' => 'distance' },
    ],
    '+as' => [
        'distance',
    ],
    order_by    => 'distance',
});

# Test setting seize propositions
while ($influence_remaining) {
    my $star = $closest->next;

    diag("Propose seizing\t".$star->x."\t".$star->y."\t ".$star->name);
    my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
        type            => 'SeizeStar',
        name            => 'Seize '.$star->name,
        description     => 'Seize control of {Starmap '.$star->x.' '.$star->y.' '.$star->name.'} by {Planet '.$station->id.' '.$station->name.'}, and apply all present laws to said star and its inhabitants.',
        scratch         => { star_id => $star->id },
        proposed_by_id  => $empire->id,
    });
    $proposition->station($station);
    $proposition->proposed_by($empire);
    $proposition->insert;
    $influence_remaining--;
}

# TODO check that we can vote on propositions.
# TODO check that stars are in order.
# TODO check that propositions are in order.

1;

