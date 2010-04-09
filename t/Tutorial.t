use lib '../lib';
use Test::More tests => 23;
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

is($tutorial->finish, 0, 'look at ui - not yet complete');
$home->name(rand(1000000));
is($tutorial->finish, 1, 'look at ui');


my $building = Lacuna::DB::Building::Food::Farm::Malcud->new(
    simpledb        => $db,
    x               => 0,
    y               => 1,
    class           => 'Lacuna::DB::Building::Food::Farm::Malcud',
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


$building = Lacuna::DB::Building::Network19->new(
    simpledb        => $db,
    x               => -5,
    y               => -5,
    class           => 'Lacuna::DB::Building::Network19',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'news');


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
    level           => 0,
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
    level           => 0,
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
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'intelligence');

$building->train_spy;

say "Waiting for spies to finish...";
sleep 216;

my $spies = $building->get_spies;
$spies->next->assign('Sting')->put;
$spies->next->assign('Counter Intelligence')->put;
sleep 3;
is($tutorial->finish, 1, 'counter spy');

$building = Lacuna::DB::Building::Observatory->new(
    simpledb        => $db,
    x               => 1,
    y               => 1,
    class           => 'Lacuna::DB::Building::Observatory',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 0,
);
$home->build_building($building);
$building->finish_upgrade;
is($tutorial->finish, 1, 'observatory');

$empire->add_probe('xxxxx');
is($tutorial->finish, 1, 'explore');
is($tutorial->finish, 1, 'the_end');
is($tutorial->finish, 1, 'turing');
is($tutorial->finish, 1, 'turing');
is($tutorial->finish, 1, 'turing');


END {
    $tester->cleanup;
}

