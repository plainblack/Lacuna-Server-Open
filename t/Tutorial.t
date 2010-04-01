use lib '../lib';
use Test::More tests => 15;
use Test::Deep;
use Data::Dumper;
use DateTime;
use 5.010;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $empire = $tester->empire;
my $home = $empire->home_planet;
my $db = $tester->db;
my $tutorial = Lacuna::Tutorial->new(empire=>$empire);

is($tutorial->finish, 1, 'look at ui');
is($tutorial->finish, 0, 'get food - not yet complete');


my $building = Lacuna::DB::Building::Food::Farm::Wheat->new(
    simpledb        => $db,
    x               => 0,
    y               => 1,
    class           => 'Lacuna::DB::Building::Food::Farm::Wheat',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'get food');


$building = Lacuna::DB::Building::Energy::Geo->new(
    simpledb        => $db,
    x               => 0,
    y               => 2,
    class           => 'Lacuna::DB::Building::Energy::Geo',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'keep the lights on');


$building = Lacuna::DB::Building::Water::Purification->new(
    simpledb        => $db,
    x               => 0,
    y               => 3,
    class           => 'Lacuna::DB::Building::Water::Purification',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'drinking water');


$building = Lacuna::DB::Building::Ore::Mine->new(
    simpledb        => $db,
    x               => 0,
    y               => 4,
    class           => 'Lacuna::DB::Building::Ore::Mine',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'mine');


$building = Lacuna::DB::Building::University->new(
    simpledb        => $db,
    x               => 0,
    y               => 5,
    class           => 'Lacuna::DB::Building::University',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'university');


$building = Lacuna::DB::Building::Ore::Storage->new(
    simpledb        => $db,
    x               => 0,
    y               => -5,
    class           => 'Lacuna::DB::Building::Ore::Storage',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
$building = Lacuna::DB::Building::Energy::Reserve->new(
    simpledb        => $db,
    x               => 0,
    y               => -4,
    class           => 'Lacuna::DB::Building::Energy::Reserve',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
$building = Lacuna::DB::Building::Food::Reserve->new(
    simpledb        => $db,
    x               => 0,
    y               => -3,
    class           => 'Lacuna::DB::Building::Food::Reserve',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
$building = Lacuna::DB::Building::Water::Storage->new(
    simpledb        => $db,
    x               => 0,
    y               => -2,
    class           => 'Lacuna::DB::Building::Water::Storage',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'storage');


$building = Lacuna::DB::Building::Food::Farm::Wheat->new(
    simpledb        => $db,
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Building::Food::Farm::Wheat',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 2,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'fool');


$building = Lacuna::DB::Building::Energy::Geo->new(
    simpledb        => $db,
    x               => 1,
    y               => -5,
    class           => 'Lacuna::DB::Building::Energy::Geo',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 3,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'energy');


$building = Lacuna::DB::Building::Water::Purification->new(
    simpledb        => $db,
    x               => 1,
    y               => -4,
    class           => 'Lacuna::DB::Building::Water::Purification',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 2,
);
$home->build_building($building);
$building->finish_upgrade;
$building = Lacuna::DB::Building::Ore::Mine->new(
    simpledb        => $db,
    x               => 1,
    y               => -3,
    class           => 'Lacuna::DB::Building::Ore::Mine',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 2,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'the 300');


$empire->description('i rule');
is($tutorial->finish, 1, 'rogue');


$building = Lacuna::DB::Building::SpacePort->new(
    simpledb        => $db,
    x               => 1,
    y               => -2,
    class           => 'Lacuna::DB::Building::SpacePort',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 1,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'spaceport');


$building = Lacuna::DB::Building::Shipyard->new(
    simpledb        => $db,
    x               => 1,
    y               => -1,
    class           => 'Lacuna::DB::Building::Shipyard',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 1,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'shipyard');


$building = Lacuna::DB::Building::Intelligence->new(
    simpledb        => $db,
    x               => 1,
    y               => 0,
    class           => 'Lacuna::DB::Building::Intelligence',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 1,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'intelligence');


END {
    $tester->cleanup;
}

