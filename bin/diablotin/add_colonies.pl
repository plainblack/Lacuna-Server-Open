use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use List::MoreUtils qw(uniq);
use Lacuna::Constants qw(FINDABLE_PLANS);
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
            my $success = add_colony($zone);
            last X if $add_one && $success;
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
    unless (defined $body) {
        say 'Could not find a colony to occupy.';
        return 0;
    }
    say $body->name;
    
    out('Colonizing '.$body->name);
    $body->found_colony($diablotin);
    
    out('Upgrading PCC');
    my $pcc = $body->command;
    $pcc->level(15);
    $pcc->update;

    out('Placing structures on '.$body->name);
    my @plans = (
        ['Lacuna::DB::Result::Building::Waste::Sequestration', 15],
        ['Lacuna::DB::Result::Building::Waste::Sequestration', 15],
        ['Lacuna::DB::Result::Building::Intelligence', 15],
        ['Lacuna::DB::Result::Building::Security', 15],
        ['Lacuna::DB::Result::Building::LuxuryHousing',10],
        ['Lacuna::DB::Result::Building::CloakingLab', 15],
        ['Lacuna::DB::Result::Building::MunitionsLab', 3],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::Shipyard', 4],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::SpacePort', 15],
        ['Lacuna::DB::Result::Building::Observatory',15],
        ['Lacuna::DB::Result::Building::Food::Syrup',15],
        ['Lacuna::DB::Result::Building::Food::Burger',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Food::Malcud',15],
        ['Lacuna::DB::Result::Building::Ore::Refinery',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Energy::Singularity',15],
        ['Lacuna::DB::Result::Building::Energy::Singularity',15],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::Production',15],
        ['Lacuna::DB::Result::Building::Water::Production',15],
        ['Lacuna::DB::Result::Building::Water::Production',15],
        ['Lacuna::DB::Result::Building::Water::Production',15],
        ['Lacuna::DB::Result::Building::Archaeology',10],
    );
    
    my @findable = FINDABLE_PLANS;
    push @plans, [$findable[rand @findable], randint(1,30)];
    
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
    return 1;
}


sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


