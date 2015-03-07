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


# TODO check that we can vote on propositions.
# TODO check that stars are in order.
# TODO check that propositions are in order.

1;

