use lib '../lib';
use Test::More tests => 6;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
$tester->cleanup; 

diag "getting session";
my $session_id = $tester->session->id;
diag "session id $session_id";
diag "getting home planet";
my $home_planet = $tester->empire->home_planet_id;
diag $home_planet;
diag "empire id ", $tester->empire->id;

my $result;
diag "check_captcha";
eval {$tester->session->check_captcha()};
if ($@) {
	is($@->[0], 1016, 'Needs to solve a captcha' );
}

diag "fetch captcha";
$result = $tester->post('captcha','fetch', []);
diag explain $result->{result};
ok(exists $result->{result}{guid}, 'Fetch captcha returned guid');
ok(exists $result->{result}{url}, 'Fetch captcha returned url');

Lacuna->cache->set('captcha', '127.0.0.1', { guid => 1111, solution => 1111 }, 60 * 30 );

diag "\$tester->post('captcha','solve', [ $session_id, 1111, 1111])";
$result = $tester->post('captcha','solve', [$session_id, 1111, 1111]);
is($result->{result}, 1, 'Solved captcha');

is($tester->empire->current_session->check_captcha(), 1, 'Captcha is still valid');

diag $tester->empire->current_session->captcha_expires;

$tester->empire->current_session->captcha_expires( time() - 60 * 30 );

is($tester->session->check_captcha, undef, 'Captcha is no longer valid');

END {
    $tester->cleanup;
}
