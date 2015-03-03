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
my $bodies = $db->resultset('Lacuna::DB::Result::Map::Body');
my $target_home = $target_player->home_planet;
my $body = $bodies->search(
    { x => {between => [ $target_home->x - 25, $target_home->x + 25 ]}, y => { between => [ $target_home->y - 25, $target_home->y + 25 ]  }, empire_id => undef, size => { between => [30,35]}}
    )->first;
die 'Could not find a colony to occupy.' unless defined $body;
say $body->name;

out('Clearing unneeded structures...');
foreach my $building (@{$body->building_cache}) {
    $building->delete;
}

out('Colonizing '.$body->name);
$body->found_colony($saben);


out('Setting target...');
$db->resultset('Lacuna::DB::Result::SabenTarget')->new({
    saben_colony_id     => $body->id,
    target_empire_id    => $target_player->id,
})->insert;

my $max_level = $target_player->university_level;
my $half_level = int( ($max_level + 1) / 2 );
my $one_third_level = int( ($max_level + 1) / 3 );
my $two_thirds_level = $one_third_level * 2;
my $quarter_level = int( ($max_level + 1) / 4 );

out('Placing structures on '.$body->name);
my @plans = (
    ['Lacuna::DB::Result::Building::Permanent::Ravine',$one_third_level, 0, 5],

    ['Lacuna::DB::Result::Building::Espionage', $two_thirds_level, -5, -4],
    ['Lacuna::DB::Result::Building::Intelligence', $two_thirds_level, -4, -4],
    ['Lacuna::DB::Result::Building::Security', $two_thirds_level, -4, -3],
    ['Lacuna::DB::Result::Building::Permanent::OracleOfAnid',1, -3, -4],
    ['Lacuna::DB::Result::Building::Permanent::LibraryOfJith',1, -3, -3],

    ['Lacuna::DB::Result::Building::Permanent::CitadelOfKnope',$one_third_level, 2, 2],
    ['Lacuna::DB::Result::Building::Observatory',1, 2, 3],
    ['Lacuna::DB::Result::Building::Shipyard',2, 2, 4],
    ['Lacuna::DB::Result::Building::SpacePort',$two_thirds_level, 2, 5],
    ['Lacuna::DB::Result::Building::SpacePort',$two_thirds_level, 3, 5],
    ['Lacuna::DB::Result::Building::Shipyard',2, 3, 4],
    ['Lacuna::DB::Result::Building::Shipyard', 2, 3, 3],
    ['Lacuna::DB::Result::Building::Propulsion',$two_thirds_level, 3, 2],
    ['Lacuna::DB::Result::Building::MunitionsLab', 5, 4, 2],
    ['Lacuna::DB::Result::Building::Permanent::CrashedShipSite',$one_third_level, 4, 3],

    ['Lacuna::DB::Result::Building::Permanent::Volcano',$half_level, -3, 2],
    ['Lacuna::DB::Result::Building::Permanent::NaturalSpring',$half_level, -3, 1],
    ['Lacuna::DB::Result::Building::Permanent::InterDimensionalRift',$half_level, -3, 3],
    ['Lacuna::DB::Result::Building::Permanent::GeoThermalVent',$half_level, -3, 0],
    ['Lacuna::DB::Result::Building::Permanent::KalavianRuins',1, -4, 1],
    ['Lacuna::DB::Result::Building::Permanent::MalcudField',$one_third_level, -4, 0],
    ['Lacuna::DB::Result::Building::Permanent::AlgaePond',$half_level, -4, 2],
    ['Lacuna::DB::Result::Building::Food::Syrup',$two_thirds_level, -4, 3],
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


