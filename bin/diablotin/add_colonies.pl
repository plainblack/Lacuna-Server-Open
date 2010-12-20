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
our $add_one;
GetOptions(
    'quiet'         => \$quiet,
    addone          => \$add_one,
);



out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
my $config = Lacuna->config;
my $empires = $db->resultset('Lacuna::DB::Result::Empire');


out('getting empires...');
my $diablotin = $empires->find(-2);
my $lec = $empires->find(1);


out('getting existing colonies');
my $colonies = $diablotin->planets;
my @existing_zones = $colonies->get_column('zone')->all;

out('Adding colonies...');
X: foreach my $x (int($config->get('map_size/x')->[0]/250) .. int($config->get('map_size/x')->[1]/250)) {
    Y: foreach my $y (int($config->get('map_size/y')->[0]/250) .. int($config->get('map_size/y')->[1]/250)) {
        my $zone = $x.'|'.$y;
        say $zone;
        if ($zone ~~ \@existing_zones) {
            say "nothing needed";
        }
        else {
            add_colony($zone);
            last X if $add_one;
        }
   }
}



my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############

sub add_colony {
    my $zone = shift;
    out('Finding colony in '.$zone.'...');
    my $body = $db->resultset('Lacuna::DB::Result::Map::Body')->search(
        { zone => $zone, empire_id => undef, size => { between => [40,49]}},
        { rows => 1, order_by => 'rand()' }
        )->single;
    die 'Could not find a colony to occupy.' unless defined $body;
    say $body->name;
    
    out('Colonizing '.$body->name);
    $body->found_colony($diablotin);
        
    out('Placing structures on '.$body->name);
    my @plans = (
        ['Lacuna::DB::Result::Building::Waste::Sequestration', 20],
        ['Lacuna::DB::Result::Building::Waste::Sequestration', 20],
        ['Lacuna::DB::Result::Building::Water::Storage', 20],
        ['Lacuna::DB::Result::Building::Water::Storage', 20],
        ['Lacuna::DB::Result::Building::Ore::Storage', 20],
        ['Lacuna::DB::Result::Building::Ore::Storage', 20],
        ['Lacuna::DB::Result::Building::Energy::Reserve', 20],
        ['Lacuna::DB::Result::Building::Energy::Reserve', 20],
        ['Lacuna::DB::Result::Building::Food::Reserve', 20],
        ['Lacuna::DB::Result::Building::Food::Reserve', 20],
        ['Lacuna::DB::Result::Building::Intelligence', 20],
        ['Lacuna::DB::Result::Building::Security', 20],
        ['Lacuna::DB::Result::Building::LuxuryHousing',15],
        ['Lacuna::DB::Result::Building::CloakingLab', 20],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::SpacePort', 20],
        ['Lacuna::DB::Result::Building::SpacePort', 20],
        ['Lacuna::DB::Result::Building::Observatory',20],
        ['Lacuna::DB::Result::Building::Food::Syrup',10],
        ['Lacuna::DB::Result::Building::Food::Burger',10],
        ['Lacuna::DB::Result::Building::Food::Malcud',20],
        ['Lacuna::DB::Result::Building::Food::Malcud',20],
        ['Lacuna::DB::Result::Building::Food::Malcud',20],
        ['Lacuna::DB::Result::Building::Food::Malcud',20],
        ['Lacuna::DB::Result::Building::Ore::Mine',20],
        ['Lacuna::DB::Result::Building::Ore::Refinery',20],
        ['Lacuna::DB::Result::Building::Waste::Digester',20],
        ['Lacuna::DB::Result::Building::Waste::Digester',20],
        ['Lacuna::DB::Result::Building::Energy::Singularity',20],
        ['Lacuna::DB::Result::Building::Water::Production',20],
        ['Lacuna::DB::Result::Building::Water::Production',20],
        ['Lacuna::DB::Result::Building::Water::Production',20],
        ['Lacuna::DB::Result::Building::Water::Production',20],
    );
    my $buildings = $db->resultset('Lacuna::DB::Result::Building');
    foreach my $plan (@plans) {
        my ($x, $y) = $body->find_free_space;
        my $building = $buildings->new({
            class   => $plan->[0],
            level   => $plan->[1] - 1,
            x       => $x,
            y       => $y,
            body_id => $body->id,
            body    => $body,
        });
        say $building->name;
        $body->build_building($building);
        $building->finish_upgrade;
    }    
}


sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


