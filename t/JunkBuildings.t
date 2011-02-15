use lib '../lib';
use Test::More; # skip_all => 'No tests are ready yet';
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
diag("session id: $session_id");
my $home_planet = $tester->empire->home_planet_id;
diag("home_planet: $home_planet");
my $empire_id = $tester->empire->id;

my $db = Lacuna->db;
my $empire = $db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
my $home = $empire->home_planet;

my @builds = (
	{ type => 'junkhengesculpture', name => 'Junk Henge Sculpture', x => 2, y => 1, },
	{ type => 'greatballofjunk', name => 'Great Ball of Junk', x => 2, y => 2, },
	{ type => 'metaljunkarches', name => 'Metal Junk Arches', x => 2, y => 3, },
	{ type => 'pyramidjunksculpture', name => 'Pyramid Junk Sculpture', x => 2, y => 4, },
	{ type => 'spacejunkpark', name => 'Space Junk Park', x => 2, y => 5, },
);

for my $build ( @builds ) {
	my $result = $tester->post($build->{type}, 'build', [$session_id, $home_planet, $build->{x}, $build->{y}]);
	is($result->{error}{code}, 1011, "Not enough waste in storage to build this.");

	$result = $tester->post('body', 'get_buildable', [$session_id, $home_planet, $build->{x}, $build->{y}, 'Waste']);

	my $amount = 0 - $result->{result}{buildable}{$build->{name}}{build}{cost}{waste};
	$home->waste_capacity($amount);
	$home->waste_stored($amount);
	$home->update;

	$result = $tester->post($build->{type}, 'build', [$session_id, $home_planet, $build->{x}, $build->{y}]);

	$build->{building} = $db->resultset('Lacuna::DB::Result::Building')->find($result->{result}{building}{id});
	$build->{building}->finish_upgrade;

	#diag explain $result;
}


END {
	for my $build ( @builds ) {
		$build->{building}->delete;
	}
    $tester->cleanup;
}

