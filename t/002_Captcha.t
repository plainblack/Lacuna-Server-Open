use lib '../lib';
use Test::More tests => 5;
use 5.010;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
$tester->cleanup; 

my $session_id = $tester->session->id;
my $home_planet = $tester->empire->home_planet_id;

Lacuna->cache->delete( 'captcha', $session_id );

my $result;
ok( ! eval { $tester->session->check_captcha }, "captcha required initially" );

$result = $tester->post('captcha','fetch', [ $session_id ]);
ok( exists $result->{result}{guid}, 'Fetch captcha returned guid' );
ok( exists $result->{result}{url}, 'Fetch captcha returned url' );

Lacuna->cache->set( 'captcha', $session_id, { guid => 1111, solution => 1111 }, 60 * 30 );

$result = $tester->post( 'captcha','solve', [ $session_id, 1111, 1111 ] );
is( $result->{result}, 1, 'Solved captcha' );

ok ( eval {$tester->session->check_captcha } , 'Captcha is valid' );

END {
    TestHelper->clear_all_test_empires;
}
