use lib '../lib';
use Test::More tests => 11;
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

my $result;

$result = $tester->post('archaeology', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built an archaeology ministry");
my $arch = $tester->get_building($result->{result}{building}{id});
$arch->level(9);
$arch->finish_upgrade;

my $odds = $arch->chance_of_glyph;
is ($arch->level, 10, 'level is set to 10');
is($odds, 10, 'odds calculated correctly');
my $successes = 0;
foreach (1..10000) {
    $successes++ if ($arch->is_glyph_found);
}
my $average = $successes / 100;
cmp_ok($average, '>=', $odds - 1, 'real life within lower limit of odds');
cmp_ok($average, '<=', $odds + 1, 'real life within upper limit of odds');

$home->bauxite_stored(99999999999);
foreach (1..100) {
    $arch->search_for_glyph('bauxite');
    $arch->finish_work;
}
$arch->update;
my $count = $home->glyphs->count;
say "Glyph Count: ".$count;
ok($count, 'got glyphs');


$result = $tester->post('archaeology', 'get_glyphs', [$session_id, $arch->id]);
ok(exists $result->{result}, 'can call get_glyphs when there are no glyphs');

$home->bauxite_stored(10000);
$home->update;

$result = $tester->post('archaeology', 'get_ores_available_for_processing', [$session_id, $arch->id]);
ok(exists $result->{result}, 'has ores for processing');

$result = $tester->post('archaeology', 'search_for_glyph', [$session_id, $arch->id, 'gold']);
ok(exists $result->{error}, 'cannot search for glyphs you do not have the ore for');

$result = $tester->post('archaeology', 'search_for_glyph', [$session_id, $arch->id, 'bauxite']);
ok(exists $result->{result}, 'can search for glyphs');

my $glyph = $home->add_glyph('rutile');

$result = $tester->post('archaeology', 'assemble_glyphs', [$session_id, $arch->id, [$glyph->id]]);
ok(exists $result->{result}, 'can assemble glyphs into a plan');


END {
    TestHelper->clear_all_test_empires;
}
