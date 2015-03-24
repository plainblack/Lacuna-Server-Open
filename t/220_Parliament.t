use lib '../lib';
use Test::More tests => 48;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna::Constants qw(ORE_TYPES);

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $friend = TestHelper->new(empire_name => 'TLE TEST Friend 1')->generate_test_empire->build_infrastructure;

my $friend2 = TestHelper->new(empire_name => 'TLE TEST Friend 2')->generate_test_empire->build_infrastructure;
$friend2->empire->is_isolationist(0);
$friend2->empire->update;

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
$empire->discard_changes;
ok $empire->alliance_id, 'empire has alliance';

$friend->empire->alliance_id($empire->alliance_id);
$friend->empire->update;

my $station = Lacuna->db->resultset('Map::Body')->search({class => {like => 'Lacuna::DB::Result::Map::Body::Planet::P%'}, empire_id => undef})->first;
$station->convert_to_station($empire);
$station->discard_changes; # just in case

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
my $big = $result->{result}{laws}[0]{id};

$result = $tester->post('parliament', 'propose_repeal_law', [$session_id, $par->id]);
is($result->{error}{data}, 5, 'repealing law requires level 5 parliament');

$par->level(5);
$par->update;

$result = $tester->post('parliament', 'propose_repeal_law', [$session_id, $par->id, $big]);
is($result->{result}{proposition}{name}, 'Repeal Do the big thing.', 'repeal law proposed');

$result = $tester->post('parliament', 'view_propositions', [$session_id, $par->id]);
my @props = sort { $b->{id} <=> $a->{id} } @{ $result->{result}{propositions} };
is($props[0]->{name}, 'Repeal Do the big thing.', 'repeal law');

$result = $tester->post('parliament', 'cast_vote', [$session_id, $par->id, $props[0]->{id}, 1]);
is($result->{result}{proposition}{my_vote}, 1, 'got my vote');

$result = $tester->post('parliament', 'propose_transfer_station_ownership', [$session_id, $par->id]);
is($result->{error}{data}, 6, 'transfering ownership of station requires level 6 parliament');

$par->level(6);
$par->update;

$result = $tester->post('parliament', 'propose_transfer_station_ownership', [$session_id, $par->id, $friend2->empire->id]);
is($result->{error}{code}, 1009, 'cannot transfer a station to a non-alliance member');

$result = $tester->post('parliament', 'propose_transfer_station_ownership', [$session_id, $par->id, $friend->empire->id]);
is($result->{error}{code}, 1013, 'cannot transfer a station to an isolationist');

$par->level(7);
$par->update;

$result = $tester->post('parliament', 'propose_rename_star', [$session_id, $par->id]);
is($result->{error}{data}, 8, 'renaming star requires level 8 parliament');

$par->level(8);
$par->update;

$result = $tester->post('parliament', 'propose_rename_star', [$session_id, $par->id, $friend->empire->home_planet->star_id, 'Jerkus']);
is($result->{error}{code}, 1009, 'star is not in range of influence');

$result = $tester->post('parliament', 'propose_broadcast_on_network19', [$session_id, $par->id]);
is($result->{error}{data}, 9, 'broadcasting on network 19 requires level 9 parliament');

$par->level(9);
$par->update;

$result = $tester->post('parliament', 'propose_broadcast_on_network19', [$session_id, $par->id, 'Kevin is the coolest']);
is($result->{result}{proposition}{name}, 'Broadcast On Network 19', 'broadcasting on network 19 proposed');

$result = $tester->post('parliament', 'propose_induct_member', [$session_id, $par->id]);
is($result->{error}{data}, 10, 'inducting new members requires level 10 parliament');

$par->level(10);
$par->update;

$result = $tester->post('parliament', 'propose_induct_member', [$session_id, $par->id, $friend->empire->id]);
is($result->{result}{proposition}{name}, 'Induct Member', 'induct member proposed');

$result = $tester->post('parliament', 'propose_elect_new_leader', [$session_id, $par->id]);
is($result->{error}{data}, 11, 'electing a new leader requires level 11 parliament');

$par->level(11);
$par->update;

$result = $tester->post('parliament', 'propose_elect_new_leader', [$session_id, $par->id, 1]);
is($result->{error}{code}, 1009, 'not an alliance member');

$result = $tester->post('parliament', 'propose_rename_asteroid', [$session_id, $par->id]);
is($result->{error}{data}, 12, 'renaming asteroid requires level 12 parliament');

$par->level(12);
$par->update;

$result = $tester->post('parliament', 'propose_rename_asteroid', [$session_id, $par->id, 1, 'Dorkus']);
is($result->{error}{code}, 1009, 'asteroid not in jurisdiction of the station');

$result = $tester->post('parliament', 'propose_members_only_mining_rights', [$session_id, $par->id]);
is($result->{error}{data}, 13, 'members mining rights requires level 13 parliament');

$par->level(13);
$par->update;

$result = $tester->post('parliament', 'propose_members_only_mining_rights', [$session_id, $par->id]);
is($result->{result}{proposition}{name}, 'Members Only Mining Rights', 'members only miningb rights proposed');

$result = $tester->post('parliament', 'propose_evict_mining_platform', [$session_id, $par->id]);
is($result->{error}{data}, 14, 'evict mining platform requires level 14 parliament');

$par->level(14);
$par->update;

$result = $tester->post('parliament', 'propose_evict_mining_platform', [$session_id, $par->id, 1]);
is($result->{error}{code}, 1002, 'platform not found');

$result = $tester->post('parliament', 'propose_taxation', [$session_id, $par->id]);
is($result->{error}{data}, 15, 'Setting a tax rate requires level 15 parliament');

$par->level(15);
$par->update;

$result = $tester->post('parliament', 'propose_taxation', [$session_id, $par->id, 5000]);
is($result->{result}{proposition}{name}, 'Tax of 5000 resources per day', 'tax rate of 5000 resources per day proposed');

$result = $tester->post('parliament', 'propose_foreign_aid', [$session_id, $par->id]);
is($result->{error}{data}, 16, 'sending foreign aid requires level 16 parliament');

$par->level(16);
$par->update;

$result = $tester->post('parliament', 'propose_foreign_aid', [$session_id, $par->id, 2, 1000]);
is($result->{error}{code}, 1009, 'planet is not within jurisdiction of the station');

$result = $tester->post('parliament', 'propose_rename_uninhabited', [$session_id, $par->id]);
is($result->{error}{data}, 17, 'renaming uninhabited requires level 17 parliament');

$par->level(17);
$par->update;

$result = $tester->post('parliament', 'propose_rename_uninhabited', [$session_id, $par->id, 1]);
is($result->{error}{code}, 1009, 'planet is not within jurisdiction of the station');

$result = $tester->post('parliament', 'propose_fire_bfg', [$session_id, $par->id]);
is($result->{error}{data}, 25, 'firing bfg requires level 25 parliament');

$par->level(25);
$par->update;

$result = $tester->post('parliament', 'propose_fire_bfg', [$session_id, $par->id, 2, 'feel like it']);
is($result->{error}{code}, 1009, 'planet is not within jurisdiction of the station');

$result = $tester->post('body', 'abandon', [$session_id, $station->id]);
is($result->{error}{code}, 1017, 'abandoning the station causes a proposition response');

$result = $tester->post('parliament', 'view_propositions', [$session_id, $par->id]);
@props = sort { $b->{id} <=> $a->{id} } @{ $result->{result}{propositions} };
is($props[0]->{name}, 'Abandon Station', 'abandon station proposed');

$result = $tester->post('parliament', 'cast_vote', [$session_id, $par->id, $props[0]->{id}, 1]);
is($result->{result}{proposition}{my_vote}, 1, 'got my vote');

$result = $tester->post('inbox','view_inbox', [$session_id]);

my @messages = sort { $b->{id} <=> $a->{id} } @{ $result->{result}{messages} };
ok($messages[0]->{subject} =~ /^Pass: Abandon Station/, 'Pass email received');

END {
    $station->sanitize;
    TestHelper->clear_all_test_empires;    
}
