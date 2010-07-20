use lib '../lib';
use Test::More tests => 4;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $result;

$result = $tester->post('archaeology', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built an archaeology ministry");
my $arch = $tester->get_building($result->{result}{building}{id});
$arch->finish_upgrade;

$result = $tester->post('archaeology', 'get_glyphs', [$session_id, $arch->id]);
ok(exists $result->{result}, 'can call get_glyphs when there are no glyphs');

$home->bauxite_stored(10000);

$result = $tester->post('archaeology', 'search_for_glyph', [$session_id, $arch->id, 'bauxite']);
ok(exists $result->{result}, 'can search for glyphs');

my $glyph = $home->add_glyph('rutile');

$result = $tester->post('archaeology', 'assemble_glyphs', [$session_id, $arch->id, [$glyph->id]]);
ok(exists $result->{result}, 'can assemble glyphs into a plan');


END {
    $tester->cleanup;
}
