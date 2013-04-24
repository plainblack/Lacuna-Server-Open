use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;

my $db = Lacuna->db;

#my $rs = $db->resultset('Map::StarLite')->search({},
#{ bind => [0,422,-10,10,-10,10] }
#);


my $starmap = $db->resultset('Map::StarLite')->get_star_map(55,1015,491,500,317,360);

diag(Dumper($starmap));
ok(1);

