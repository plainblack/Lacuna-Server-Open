use lib '../lib';
use Test::More tests => 90;
use 5.010;
use Lacuna;
use DateTime;
use TestHelper;

# Set up a planet that can be used for AI Attacks, both to and against

my $tester = TestHelper->new({empire_name => 'TLE Test Empire'});
my $empire = $tester->empire;
my $session = $empire->start_session({api_key => 'tester'});

my ($planet) = Lacuna->db->resultset('Map::Body::Planet')->search({name => 'Smith 3'});

$tester->build_big_colony($session, $planet);

