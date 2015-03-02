use lib '../lib';
use Test::More tests => 14;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;

my $tester = TestHelper->new({empire_name => 'icydee'});

$tester->use_existing_test_empire;
diag("tester = [$tester]");

my $session_id  = $tester->session->id;
my $empire      = $tester->empire;
my $home        = $empire->home_planet;

my $oracle      = $home->oracle;
isnt($oracle, undef, "Planet has an oracle");

$result = $tester->post('oracleofanid', 'get_probed_stars', [{
    session_id      => $session_id,
    building_id     => $oracle->id,
    page_size       => 2,
    page_number     => 1,
}]);



