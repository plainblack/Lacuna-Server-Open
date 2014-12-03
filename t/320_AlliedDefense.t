use lib '../lib';
use Test::More tests => 90;
use 5.010;
use DateTime;
use Math::Complex; # used for asteroid and planet selection

use TestHelper;
Helper->clear_all_test_empires;

my @testers = ( 
	TestHelper->new->generate_test_empire->build_infrastructure,
	TestHelper->new(empire_name => 'TLE Test Enemy')->generate_test_empire->build_infrastructure,
);

my @asteroids = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
	{ zone => $testers[0]->empire->home_planet->zone, size => 10, class => { like => 'Lacuna::DB::Result::Map::Body::Asteroid%' } },
)->all();

my @planets = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(
	{ zone => $testers[0]->empire->home_planet->zone, orbit => 3, class => { like => 'Lacuna::DB::Result::Map::Body::Planet::P%'} },
)->all();


my $result;

for my $tester ( @testers ) {
	my $session_id = $tester->session->id;
	my $empire = $tester->empire;
	my $home = $empire->home_planet;
	my $command = $home->command;

	Lacuna->cache->set('captcha', $session_id, { guid => 1111, solution => 1111 }, 60 * 30 );

	$result = $tester->post('captcha','solve', [$session_id, 1111, 1111]);
	is($result->{result}, 1, 'Solved captcha');

	my $uni = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
			x               => -5,
			y               => 5,
			class           => 'Lacuna::DB::Result::Building::University',
			level           => 10,
			});
	$home->build_building($uni);
	$uni->finish_upgrade;

	$home->ore_hour(50000000);
	$home->water_hour(50000000);
	$home->energy_hour(50000000);
	$home->algae_production_hour(50000000);
	$home->ore_capacity(50000000);
	$home->energy_capacity(50000000);
	$home->food_capacity(50000000);
	$home->water_capacity(50000000);
	$home->bauxite_stored(50000000);
	$home->algae_stored(50000000);
	$home->energy_stored(50000000);
	$home->water_stored(50000000);
	$home->add_happiness(50000000);
	$home->needs_recalc(0);
	$home->update;

	$empire->is_isolationist(0);
	$empire->update;

	my $spaceport = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
			x		=> -4,
			y		=> 5,
			class	=> 'Lacuna::DB::Result::Building::SpacePort',
			level	=> 10,
			});
	$home->build_building($spaceport);
	$spaceport->finish_upgrade;
	$tester->{spaceport_id} = $spaceport->id;

	my $shipyard = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
			x       => -3,
			y       => 5,
			class   => 'Lacuna::DB::Result::Building::Shipyard',
			level   => 10,
			});
	$home->build_building($shipyard);
	$shipyard->finish_upgrade;

	my $miningmin = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
			x       => -2,
			y       => 5,
			class   => 'Lacuna::DB::Result::Building::Ore::Ministry',
			level   => 10,
			});
	$home->build_building($miningmin);
	$miningmin->finish_upgrade;

	my $munitions = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
			x       => -1,
			y       => 5,
			class   => 'Lacuna::DB::Result::Building::MunitionsLab',
			level   => 10,
			});
	$home->build_building($munitions);
	$munitions->finish_upgrade;

	my $observatory = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
			x       => 0,
			y       => 5,
			class   => 'Lacuna::DB::Result::Building::Observatory',
			level   => 10,
			});
	$home->build_building($observatory);
	$observatory->finish_upgrade;

	my $saw = Lacuna::db->resultset('Lacuna::DB::Result::Building')->new({
			x       => 1,
			y       => 5,
			class   => 'Lacuna::DB::Result::Building::SAW',
			level   => 10,
			});
	$home->build_building($saw);
	$saw->finish_upgrade;

	my $probe = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'probe'});
	$shipyard->build_ship($probe);

	my $fighter = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'fighter'});
	$shipyard->build_ship($fighter);

	my $fighter2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'fighter'});
	$shipyard->build_ship($fighter2);

	my $fighter3 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'fighter'});
	$shipyard->build_ship($fighter3);

	my $sweeper = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'sweeper'});
	$shipyard->build_ship($sweeper);

	my $sweeper2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'sweeper'});
	$shipyard->build_ship($sweeper2);

	my $detonator = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'detonator'});
	$shipyard->build_ship($detonator);

	my $detonator2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'detonator'});
	$shipyard->build_ship($detonator2);

	my $miningship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'mining_platform_ship'});
	$shipyard->build_ship($miningship);

	my $miningship2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'mining_platform_ship'});
	$shipyard->build_ship($miningship2);

	my $stake = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'stake'});
	$shipyard->build_ship($stake);

	my $colonyship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>'colony_ship'});
	$shipyard->build_ship($colonyship);

	my $finish = DateTime->now;
	Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id=>$shipyard->id})->update({date_available=>$finish});

	$result = $tester->post('spaceport', 'view', [$session_id, $spaceport->id]);
	is($result->{result}{docked_ships}{probe}, 1, "we have 1 probe built");
	is($result->{result}{docked_ships}{fighter}, 3, "we have 3 fighters built");
	is($result->{result}{docked_ships}{sweeper}, 2, "we have 2 sweepers built");
	is($result->{result}{docked_ships}{detonator}, 2, "we have 2 detonators built");
	is($result->{result}{docked_ships}{mining_platform_ship}, 2, "we have 2 mining platform ships built");
	is($result->{result}{docked_ships}{stake}, 1, "we have 1 stake built");
	is($result->{result}{docked_ships}{colony_ship}, 1, "we have 1 colony ship built");

	# Find the closest asteroid
	my @distance;
	for my $ast ( @asteroids ) {
		my $dist = sqrt( ($home->x - $ast->x)**2 + ($home->y - $ast->y)**2 );
		my $name = $ast->name;
		$name =~ s/\r/ /g;
		push @distance, {
			x		=> $ast->x,
			y		=> $ast->y,
			orbit	=> $ast->orbit,
			name	=> $name,
			dist	=> $dist,
		};
	}
	@distance = sort { $a->{dist} <=> $b->{dist} } @distance;
	my $asteroid = shift @distance;
	$tester->{asteroid} = $asteroid;

	# Find the closest habitable planet
	@distance = ();
	for my $planet ( @planets ) {
		next if ( $planet->x == $home->x && $planet->y == $home->y );
		my $dist = sqrt( ($home->x - $planet->x)**2 + ($home->y - $planet->y)**2 );
		my $name = $planet->name;
		$name =~ s/\r/ /g;
		push @distance, {
			x		=> $planet->x,
			y		=> $planet->y,
			orbit	=> $planet->orbit,
			name	=> $name,
			dist	=> $dist,
		};
	}
	@distance = sort { $a->{dist} <=> $b->{dist} } @distance;
	my $planet = shift @distance;
	$tester->{planet} = $planet;
}

for my $i ( 0 .. 1 ) {
	my $j = 1 - $i;

	my $tester = $testers[$i];
	my %tester;
	$tester{session_id}	= $tester->session->id;
	$tester{empire} = $tester->empire;
	$tester{home} = $tester{empire}->home_planet;
	$tester{command} = $tester{home}->command;
	$tester{asteroid} = $tester->{asteroid};
	$tester{planet} = $tester->{planet};

	my $enemy = $testers[$j];
	my %enemy;
	$enemy{session_id}	= $enemy->session->id;
	$enemy{empire} = $enemy->empire;
	$enemy{home} = $enemy{empire}->home_planet;
	$enemy{command} = $enemy{home}->command;
	$enemy{asteroid} = $enemy->{asteroid};
	$enemy{planet} = $enemy->{planet};

	my $asteroid = $tester{asteroid};	
	my $planet = $tester{planet};	

	# Send a probe to the enemy's star
	my $probe = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'probe'})->first;
	diag "Sending ship ", $probe->id, " type ", $probe->type, " to star_id ", $enemy{home}->star_id;
	$result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $probe->id, {star_id=>$enemy{home}->star_id}]);
	diag "Probe arrives ", $result->{result}{ship}{date_arrives};
	ok($result->{result}{ship}{date_arrives}, "probe sent");
	$probe = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$probe->id})->first; # pull the latest data on this ship
	$probe->arrive;

	# Send a mining platform ship to the closest asteroid
	my $miningship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'mining_platform_ship'})->first;
	diag "Sending ship ", $miningship->id, " type ", $miningship->type, " to ", $asteroid->{x}, ",", $asteroid->{y};
	$result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $miningship->id, {x=>$asteroid->{x},y=>$asteroid->{y}}]);
	diag "Mining Platform Ship arrives ", $result->{result}{ship}{date_arrives};
	ok($result->{result}{ship}{date_arrives}, "mining platform ship sent");
	$miningship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$miningship->id})->first; # pull the latest data on this ship
	$miningship->arrive;

	# Send a fighter to defend the closest asteroid
	my $fighter = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'fighter', task=>'Docked'})->first;
    diag "Sending ship ", $fighter->id, " type ", $fighter->type, " to ", $asteroid->{x}, ",", $asteroid->{y};
    $result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $fighter->id, { x => $asteroid->{x}, y => $asteroid->{y} }]);
    diag "Fighter arrives ", $result->{result}{ship}{date_arrives};
    ok($result->{result}{ship}{date_arrives}, "fighter sent");
    $fighter = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$fighter->id})->first; # pull the latest data on this ship
    $fighter->arrive;

	$result = $tester->post('spaceport', 'get_ships_for', [$tester{session_id}, $tester{home}->id, { x => $asteroid->{x}, y => $asteroid->{y} } ]);
	is( @{ $result->{result}{orbiting} }, 1, 'one ship is orbiting' );

	# Send a fighter to defend the closest planet
	my $fighter2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'fighter', task=>'Docked'})->first;
    diag "Sending ship ", $fighter2->id, " type ", $fighter2->type, " to ", $planet->{x}, ",", $planet->{y};
    $result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $fighter2->id, { x => $planet->{x}, y => $planet->{y} }]);
    diag "Fighter arrives ", $result->{result}{ship}{date_arrives};
    ok($result->{result}{ship}{date_arrives}, "fighter2 sent");
    $fighter2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$fighter2->id})->first; # pull the latest data on this ship
    $fighter2->arrive;
	$tester->{fighter2} = $fighter2->id;

	$result = $tester->post('spaceport', 'get_ships_for', [$tester{session_id}, $tester{home}->id, { x => $planet->{x}, y => $planet->{y} } ]);
	is( @{ $result->{result}{orbiting} }, 1, 'one ship is orbiting' );

	$result = $tester->post('spaceport', 'view_all_ships', [$tester{session_id}, $tester->{spaceport_id}]);
	for my $ship ( @{ $result->{result}{ships} } ) {
		if ( $ship->{type} ) {
			if ( $ship->{id} == $fighter->id ) {
				is( $ship->{task}, 'Defend', 'fighter is orbiting' );
				ok( $ship->{orbiting}{id}, 'orbiting has an id' );
				ok( $ship->{orbiting}{name}, 'orbiting has a name' );
				is( $ship->{orbiting}{x}, $asteroid->{x}, 'orbiting x matches x of target' );
				is( $ship->{orbiting}{y}, $asteroid->{y}, 'orbiting x matches x of target' );
				ok( $ship->{from}{id}, 'from has an id' );
				ok( $ship->{from}{name}, 'from has a name' );
			}
			elsif ( $ship->{id} == $fighter2->id ) {
				is( $ship->{task}, 'Defend', 'fighter2 is orbiting' );
				ok( $ship->{orbiting}{id}, 'orbiting has an id' );
				ok( $ship->{orbiting}{name}, 'orbiting has a name' );
				is( $ship->{orbiting}{x}, $planet->{x}, 'orbiting x matches x of target' );
				is( $ship->{orbiting}{y}, $planet->{y}, 'orbiting x matches x of target' );
				ok( $ship->{from}{id}, 'from has an id' );
				ok( $ship->{from}{name}, 'from has a name' );
			}
		}
	}
	
}

for my $i ( 0 .. 1 ) {
	my $j = 1 - $i;

	my $tester = $testers[$i];
	my %tester;
	$tester{session_id}	= $tester->session->id;
	$tester{empire} = $tester->empire;
	$tester{home} = $tester{empire}->home_planet;
	$tester{command} = $tester{home}->command;
	$tester{asteroid} = $tester->{asteroid};
	$tester{planet} = $tester->{planet};

	my $enemy = $testers[$j];
	my %enemy;
	$enemy{session_id}	= $enemy->session->id;
	$enemy{empire} = $enemy->empire;
	$enemy{home} = $enemy{empire}->home_planet;
	$enemy{command} = $enemy{home}->command;
	$enemy{asteroid} = $enemy->{asteroid};
	$enemy{planet} = $enemy->{planet};

	my $asteroid = $enemy{asteroid};
	my $planet = $enemy{planet};

	# Send a sweeper to the enemy's asteroid
	my $sweeper = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'sweeper'})->first;
    diag "Sending ship ", $sweeper->id, " type ", $sweeper->type, " to ", $asteroid->{x}, ",", $asteroid->{y};
    $result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $sweeper->id, { x => $asteroid->{x}, y => $asteroid->{y} }]);
    diag "Sweeper arrives ", $result->{result}{ship}{date_arrives};
    ok($result->{result}{ship}{date_arrives}, "sweeper sent");
    $sweeper = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$sweeper->id})->first; # pull the latest data on this ship
    $sweeper->arrive;
	
	$result = $tester->post('spaceport', 'view_all_ships', [$tester{session_id}, $tester->{spaceport_id}]);
	my %ships;
	for my $ship ( @{ $result->{result}{ships} } ) {
		$ships{$ship->{type}}++;
	}
	is( $result->{result}{status}{empire}{most_recent_message}{subject}, "Ship Shot Down", 'Ship shot down' );
	is( $ships{sweeper}, 1, 'One sweeper left' );

	# Send a fighter to enemy asteroid
	my $fighter3 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'fighter', task=>'Docked'})->first;
    diag "Sending ship ", $fighter3->id, " type ", $fighter3->type, " to ", $asteroid->{x}, ",", $asteroid->{y};
    $result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $fighter3->id, { x => $asteroid->{x}, y => $asteroid->{y} }]);
    diag "Fighter arrives ", $result->{result}{ship}{date_arrives};
    ok($result->{result}{ship}{date_arrives}, "fighter3 sent");
    $fighter3 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$fighter3->id})->first; # pull the latest data on this ship
    $fighter3->arrive;

	$result = $tester->post('spaceport', 'view_all_ships', [$tester{session_id}, $tester->{spaceport_id}]);
	my %ships;
	for my $ship ( @{ $result->{result}{ships} } ) {
		if ( $ship->{type} ) {
			if ( $ship->{id} == $fighter3->id ) {
				is( $ship->{task}, 'Defend', 'fighter3 is defending' );
			}
		}
	}

	# Recall it
    $fighter3 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$fighter3->id})->first; # pull the latest data on this ship
	$result = $tester->post('spaceport', 'recall_ship', [$tester{session_id}, $tester->{spaceport_id}, $fighter3->id]);
    diag "Fighter arrives ", $result->{result}{ship}{date_arrives};
    ok($result->{result}{ship}{date_arrives}, "fighter recalled");
    $fighter3 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$fighter3->id})->first; # pull the latest data on this ship
    $fighter3->arrive;

	# Send a mining platform ship to the enemy asteroid
	my $miningship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'mining_platform_ship'})->first;
	diag "Sending ship ", $miningship->id, " type ", $miningship->type, " to ", $asteroid->{x}, ",", $asteroid->{y};
	$result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $miningship->id, {x=>$asteroid->{x},y=>$asteroid->{y}}]);
	diag "Mining Platform Ship arrives ", $result->{result}{ship}{date_arrives};
	ok($result->{result}{ship}{date_arrives}, "mining platform ship sent");
	$miningship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$miningship->id})->first; # pull the latest data on this ship
	$miningship->arrive;

	my $fighter2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$enemy->{fighter2}})->first;
	diag "Enemy fighter 2 is at ", $fighter2->foreign_body_id, " task ", $fighter2->task, " combat ", $fighter2->combat;
	$result = $tester->post('spaceport', 'view_all_ships', [$enemy{session_id}, $enemy->{spaceport_id}]);


	# Send a stake to the enemy's closest planet
	my $stake = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'stake'})->first;
	diag "Sending ship ", $stake->id, " type ", $stake->type, " to ", $planet->{x}, ",", $planet->{y};
	$result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $stake->id, {x=>$planet->{x},y=>$planet->{y}}]);
        # Cannot send a stake to an inhabited planet	
        is($result->{error}{code}, 1013, "Cannot send stake to inhabited planet");
 
	$result = $tester->post('spaceport', 'view', [$tester{session_id}, $tester->{spaceport_id}]);
	is( $result->{result}{status}{empire}{most_recent_message}{subject}, "Ship Shot Down", 'Stake shot down' );

	# Accelerate reset period
	$fighter2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$enemy->{fighter2}})->first;
	diag "Enemy fighter 2 is at ", $fighter2->foreign_body_id, " task ", $fighter2->task, " combat ", $fighter2->combat;
    $fighter2->arrive;
	$fighter2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$enemy->{fighter2}})->first;
    $fighter2->arrive;
	$fighter2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$enemy->{fighter2}})->first;
	diag "Enemy fighter 2 is at ", $fighter2->foreign_body_id, " task ", $fighter2->task, " combat ", $fighter2->combat;
	$result = $tester->post('spaceport', 'view_all_ships', [$enemy{session_id}, $enemy->{spaceport_id}]);

	$tester{home}->add_happiness(50000000);;
	$tester{home}->needs_recalc(0);
	$tester{home}->update;

	# Send a colony ship to the enemy's closest planet
	my $colony_ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'colony_ship'})->first;
	diag "Sending ship ", $colony_ship->id, " type ", $colony_ship->type, " to ", $planet->{x}, ",", $planet->{y};
	$result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $colony_ship->id, {x=>$planet->{x},y=>$planet->{y}}]);
	diag "Colony ship arrives ", $result->{result}{ship}{date_arrives};
	ok($result->{result}{ship}{date_arrives}, "colony ship sent");
	$colony_ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$colony_ship->id})->first; # pull the latest data on this ship
	$colony_ship->arrive;

	$result = $tester->post('spaceport', 'view_all_ships', [$tester{session_id}, $tester->{spaceport_id}]);
	my %ships;
	for my $ship ( @{ $result->{result}{ships} } ) {
		if ( $ship->{type} ) {
			if ( $ship->{id} == $fighter3->id ) {
				is( $ship->{task}, 'Docked', 'fighter3 was recalled' );
			}
		}
	}
	is( $result->{result}{status}{empire}{most_recent_message}{subject}, "Colony Founded", 'Colony founded' );

	my $detonator = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'detonator'})->first;
	diag "Sending ship ", $detonator->id, " type ", $detonator->type, " to star_id ", $enemy{home}->star_id;
	$result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $detonator->id, {star_id=>$enemy{home}->star_id}]);
	diag "Detonator arrives ", $result->{result}{ship}{date_arrives};
	ok($result->{result}{ship}{date_arrives}, "Detonator sent");
	$detonator = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$detonator->id})->first; # pull the latest data on this ship
	$detonator->arrive;

	$result = $tester->post('spaceport', 'view', [$tester{session_id}, $tester->{spaceport_id}]);
	is( $result->{result}{status}{empire}{most_recent_message}{subject}, "Detonator Report", 'Detonator took out probes' );

	my $detonator2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $tester{home}->id, type=>'detonator'})->first;
	diag "Sending ship ", $detonator2->id, " type ", $detonator2->type, " to ", $asteroid->{x}, ",", $asteroid->{y};
	$result = $tester->post('spaceport', 'send_ship', [$tester{session_id}, $detonator2->id, {x=>$asteroid->{x},y=>$asteroid->{y}}]);
	diag "Detonator arrives ", $result->{result}{ship}{date_arrives};
	ok($result->{result}{ship}{date_arrives}, "Detonator sent");
	$detonator2 = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({id=>$detonator2->id})->first; # pull the latest data on this ship
	$detonator2->arrive;

	$result = $tester->post('spaceport', 'view', [$tester{session_id}, $tester->{spaceport_id}]);
	is( $result->{result}{status}{empire}{most_recent_message}{subject}, "Detonator Report", 'Detonator took out mining platforms' );

    $result = $tester->post('spaceport', 'view_battle_logs', [$tester{session_id}, $tester->{spaceport_id} ]);
    ok(scalar @{$result->{result}{battle_log}}, "Battle logs retrieved");
diag explain $result->{result}{battle_log};
}

END {
    TestHelper->clear_all_test_empires;
}
