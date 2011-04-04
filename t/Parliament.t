use lib '../lib';
use Test::More tests => 27;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna::Constants qw(ORE_TYPES);

use TestHelper;
my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $emb = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => 4,
        y               => 4,
        class           => 'Lacuna::DB::Result::Building::Embassy',
    });
$home->build_building($emb);
$emb->finish_upgrade;

my $result;
$result = $tester->post('embassy', 'create_alliance', [$session_id, $emb->id, 'test alliance']);
ok(exists $result->{result}, 'can create alliance');
$result = $tester->post('embassy', 'get_alliance_status', [$session_id, $emb->id]);
ok(scalar@{$result->{result}{alliance}{members}}, 'alliance has members');
$empire = $empire->get_from_storage;
ok $empire->alliance_id, 'empire has alliance';

my $station = Lacuna->db->resultset('Map::Body')->search({class => {like => 'Lacuna::DB::Result::Map::Body::Planet::P%'}, empire_id => undef},{rows=>1})->single;
$station->convert_to_station($empire);
$station = $station->get_from_storage; # just in case

ok $station->alliance_id, 'alliance assigned to station';

my $par = $station->parliament;
$par->level(4);
$par->update;
    
$result = $tester->post('parliament', 'view', [$session_id, $par->id]);
is($result->{result}{building}{name}, 'Parliament', 'built successfully');

$result = $tester->post('body', 'rename', [$session_id, $station->id, 'station'.rand(1000000)]);
is($result->{error}{code}, 1017, 'renaming the station causes a proposition response');

$result = $tester->post('parliament', 'get_stars_in_jurisdiction', [$session_id, $par->id]);
is(scalar @{$result->{result}{stars}}, 0, 'got a list of zero stars');

$result = $tester->post('parliament', 'view_propositions', [$session_id, $par->id]);
is($result->{result}{propositions}[0]{name}, 'Rename Station', 'got a list of propositions');

$result = $tester->post('parliament', 'cast_vote', [$session_id, $par->id, $result->{result}{propositions}[0]{id}, 1]);
is($result->{result}{proposition}{my_vote}, 1, 'got my vote');

$empire->pay_taxes($station->id,500);
$result = $tester->post('parliament', 'view_taxes_collected', [$session_id, $par->id]);
is($result->{result}{taxes_collected}[0]{name}, $empire->name, 'found my payment');
is($result->{result}{taxes_collected}[0]{total}, 500, 'my payment is correct');

$result = $tester->post('parliament', 'propose_writ', [$session_id, $par->id, 'Do the big thing.', 'Make it go.']);
is($result->{result}{proposition}{name}, 'Do the big thing.', 'writ proposed');
$result = $tester->post('parliament', 'cast_vote', [$session_id, $par->id, $result->{result}{proposition}{id}, 1]);
$result = $tester->post('parliament', 'view_laws', [$session_id, $station->id]);
is($result->{result}{laws}[0]{name}, 'Do the big thing.', 'writ enacted');

$result = $tester->post('parliament', 'propose_repeal_law', [$session_id, $par->id]);
is($result->{error}{data}, 5, 'repealing law requires level 5 parliament');

$result = $tester->post('parliament', 'propose_transfer_station_ownership', [$session_id, $par->id]);
is($result->{error}{data}, 6, 'transfering ownership of station requires level 6 parliament');

$result = $tester->post('parliament', 'propose_seize_star', [$session_id, $par->id]);
is($result->{error}{data}, 7, 'seizing star requires level 7 parliament');

$result = $tester->post('parliament', 'propose_rename_star', [$session_id, $par->id]);
is($result->{error}{data}, 8, 'renaming star requires level 8 parliament');

$result = $tester->post('parliament', 'propose_broadcast_on_network19', [$session_id, $par->id]);
is($result->{error}{data}, 9, 'broadcasting on network 19 requires level 9 parliament');

$result = $tester->post('parliament', 'propose_induct_member', [$session_id, $par->id]);
is($result->{error}{data}, 10, 'inducting new members requires level 10 parliament');

$result = $tester->post('parliament', 'propose_expel_member', [$session_id, $par->id]);
is($result->{error}{data}, 10, 'expelling members requires level 10 parliament');

$result = $tester->post('parliament', 'propose_elect_new_leader', [$session_id, $par->id]);
is($result->{error}{data}, 11, 'electing a new leader requires level 11 parliament');

$result = $tester->post('parliament', 'propose_rename_asteroid', [$session_id, $par->id]);
is($result->{error}{data}, 12, 'renaming asteroid requires level 12 parliament');

$result = $tester->post('parliament', 'propose_members_only_mining_rights', [$session_id, $par->id]);
is($result->{error}{data}, 13, 'members mining rights requires level 13 parliament');

$result = $tester->post('parliament', 'propose_evict_mining_platform', [$session_id, $par->id]);
is($result->{error}{data}, 14, 'evict mining platform requires level 14 parliament');

$result = $tester->post('parliament', 'propose_taxation', [$session_id, $par->id]);
is($result->{error}{data}, 15, 'Setting a tax rate requires level 15 parliament');

$result = $tester->post('parliament', 'propose_rename_uninhabited', [$session_id, $par->id]);
is($result->{error}{data}, 17, 'renaming uninhabited requires level 17 parliament');

$result = $tester->post('parliament', 'propose_fire_bfg', [$session_id, $par->id]);
is($result->{error}{data}, 25, 'firing bfg requires level 25 parliament');


END {
    $station->sanitize;
    $tester->cleanup;
}
