use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use List::MoreUtils qw(uniq);
$|=1;
our $quiet;
our $target;
GetOptions(
    'quiet'         => \$quiet,
    'target-player=s'        => \$target,
);

die 'You need to specify a target player.' unless $target;


out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
my $empires = $db->resultset('Lacuna::DB::Result::Empire');


out('getting empires...');
my $saben = $empires->find(-1);
my $lec = $empires->find(1);
my $target_player = $empires->find($target);
die 'Could not find target player.' unless defined $target_player;


out('Finding colony...');
my $body = $db->resultset('Lacuna::DB::Result::Map::Body')->search(
    { zone => $target_player->home_planet->zone, empire_id => undef, size => { between => [30,35]}},
    { rows => 1 }
    )->single;
die 'Could not find a colony to occupy.' unless defined $body;
say $body->name;

out('Clearing unneeded structures...');
my $buildings = $body->buildings;
while (my $building = $buildings->next) {
    $building->delete;
}

out('Colonizing '.$body->name);
$body->found_colony($saben);


out('Setting target...');
$db->resultset('Lacuna::DB::Result::SabenTarget')->new({
    saben_colony_id     => $body->id,
    target_empire_id    => $target_player->id,
})->insert;


out('Placing structures on '.$body->name);
my @plans = (
    ['Lacuna::DB::Result::Building::Permanent::Ravine',3, -2, 2],
    ['Lacuna::DB::Result::Building::Intelligence', $target_player->university_level, -1, 2],
    ['Lacuna::DB::Result::Building::Security', 10, 0, 2],
    ['Lacuna::DB::Result::Building::Espionage', 15, 1, 2],
    ['Lacuna::DB::Result::Building::Permanent::CitadelOfKnope',5, 2, 2],

    ['Lacuna::DB::Result::Building::Permanent::OracleOfAnid',1, -2, 1],
    ['Lacuna::DB::Result::Building::Shipyard',5, -1, 1],
    ['Lacuna::DB::Result::Building::EntertainmentDistrict',9, 0, 1],
    ['Lacuna::DB::Result::Building::Permanent::Volcano',7, 1, 1],
    ['Lacuna::DB::Result::Building::Waste::Sequestration',10, 2, 1],

    ['Lacuna::DB::Result::Building::MunitionsLab',5, -2, 0],
    ['Lacuna::DB::Result::Building::SpacePort',10, -1, 0],
    # PCC 0,0
    ['Lacuna::DB::Result::Building::Permanent::NaturalSpring',8, 1, 0],
    ['Lacuna::DB::Result::Building::Permanent::InterDimensionalRift',7, 2, 0],

    ['Lacuna::DB::Result::Building::Observatory',1, -2, -1],
    ['Lacuna::DB::Result::Building::Shipyard',5, -1, -1],
    ['Lacuna::DB::Result::Building::Trade',10, 0, -1],
    ['Lacuna::DB::Result::Building::Permanent::GeoThermalVent',7, 1, -1],
    ['Lacuna::DB::Result::Building::Permanent::MalcudField',6, 2, -1],

    ['Lacuna::DB::Result::Building::Permanent::LibraryOfJith',1, -2, -2],
    ['Lacuna::DB::Result::Building::SpacePort',10, -1, -2],
    ['Lacuna::DB::Result::Building::Permanent::CrashedShipSite',5, 0, -2],
    ['Lacuna::DB::Result::Building::Permanent::AlgaePond',6, 1, -2],
    ['Lacuna::DB::Result::Building::Food::Syrup',10, 2, -2],
);
$buildings = $db->resultset('Lacuna::DB::Result::Building');
foreach my $plan (@plans) {
    my $building = $buildings->new({
        class   => $plan->[0],
        level   => $plan->[1] - 1,
        x       => $plan->[2],
        y       => $plan->[3],
        body_id => $body->id,
        body    => $body,
    });
    say $building->name;
    $body->build_building($building);
    $building->finish_upgrade;
}


my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############




sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


