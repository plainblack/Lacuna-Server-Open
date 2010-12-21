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
my $viable_colonies = $db->resultset('Lacuna::DB::Result::Map::Body')->search(
                { empire_id => undef, orbit => 7, size => { between => [41,49]}},
                { rows => 1, order_by => 'rand()' }
                );
my $lec = $empires->find(1);
my $diablotin = $empires->find(-2);
unless (defined $diablotin) {
    $diablotin = create_empire();
}


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
            out('Finding colony in '.$zone.'...');
            my $body = $viable_colonies->search({zone => $zone})->single;
            if (defined $body) {
                out('Colonizing '.$body->name);
                $body->found_colony($diablotin);
                build_colony($body);
                last X if $add_one;
            }
            else {
                say 'Could not find a colony to occupy.';
            }
        }
    }
}



my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############

sub build_colony {
    my $body = shift;    
    
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
        ['Lacuna::DB::Result::Building::Ore::Refinery',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Waste::Digester',15],
        ['Lacuna::DB::Result::Building::Energy::Singularity',15],
        ['Lacuna::DB::Result::Building::Energy::Singularity',13],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
        ['Lacuna::DB::Result::Building::Water::Reclamation',15],
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
}

sub create_empire {
    out('Creating empire...');
    my $empire = $empires->new({
        id                  => -2,
        name                => 'Diablotin',
        stage               => 'founded',
        date_created        => DateTime->now,
        status_message      => 'Vous tes le bouffon!',
        description         => 'La plaisanterie est sur toi.',
        password            => Lacuna::DB::Result::Empire->encrypt_password(rand(99999999)),
        university_level    => 30,
        species_name            => 'Diablotin',
        species_description     => 'Nous aimons nous amuser.',
        min_orbit               => 7,
        max_orbit               => 7,
        manufacturing_affinity  => 7, # cost of building new stuff
        deception_affinity      => 7, # spying ability
        research_affinity       => 1, # cost of upgrading
        management_affinity     => 1, # speed to build
        farming_affinity        => 6, # food
        mining_affinity         => 1, # minerals
        science_affinity        => 7, # energy, propultion, and other tech
        environmental_affinity  => 6, # waste and water
        political_affinity      => 6, # happiness
        trade_affinity          => 1, # speed of cargoships, and amount of cargo hauled
        growth_affinity         => 1, # price and speed of colony ships, and planetary command center start level
    });
    
    out('Find home planet...');
    my $bodies = $db->resultset('Lacuna::DB::Result::Map::Body');
    my $zone = $bodies->get_column('zone')->max;
    my $home = $viable_colonies->search({zone => $zone})->single;
    $empire->insert;
    $empire->found($home);
    build_colony($home);
    return $empire;
}

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


