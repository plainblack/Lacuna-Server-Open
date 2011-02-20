use lib '../lib';
use Test::More tests => 5;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = eval{TestHelper->new->generate_test_empire};
if ($@) {
	die $@->[1];
}
my $session_id = $tester->session->id;
my $home_planet = $tester->empire->home_planet_id;

my $result;

is($tester->session->check_captcha, undef, 'Captcha is not valid');

$result = $tester->post('captcha','fetch', []);
diag explain $result;
ok(exists $result->{result}{guid}, 'Fetch captcha returned guid');
ok(exists $result->{result}{url}, 'Fetch captcha returned url');

Lacuna->cache->set('captcha', '127.0.0.1', { guid => 1111, solution => 1111 }, 60 * 30 );

$result = $tester->post('captcha','solve', [$session_id, 1111, 1111]);
is($result->{result}, 1, 'Solved captcha');

is($tester->session->check_captcha, 1, 'Captcha is still valid');

END {
    $tester->cleanup;
}
