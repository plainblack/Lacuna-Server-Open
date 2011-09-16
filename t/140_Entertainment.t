use lib '../lib';
use Test::More tests => 5;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $cache = Lacuna->cache;
my $ymd = DateTime->now->ymd;

my $result;

$result = $tester->post('entertainment', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built an ed");
my $ed = $tester->get_building($result->{result}{building}{id});
$ed->finish_upgrade;

$result = $tester->post('entertainment', 'get_lottery_voting_options', [$session_id, $ed->id]);
is($result->{result}{options}[0]{name}, Lacuna->config->get('voting_sites')->[0]{name}, "got lottery voting options");

my $ua = $tester->ua;
$ua->requests_redirectable([]);
my $response = $ua->get($result->{result}{options}[0]{url});
is($response->code, 302, 'get a redirect');
my $zone = $ed->body->zone;
ok($cache->get('high_vote'.$zone, $ymd), 'high_vote gets set');
ok($cache->get('high_vote_empire'.$zone, $ymd), 'high_vote_empire gets set');


END {
    TestHelper->clear_all_test_empires;
    $cache->set('high_vote'.$zone, $ymd);
    $cache->set('high_vote_empire'.$zone, $ymd);
}
