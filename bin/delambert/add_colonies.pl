use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';

use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);

use Getopt::Long;
use List::MoreUtils qw(uniq);
use Data::Dumper;

$|=1;
our $quiet      = 0; # omit output messages
our $respawn    = 0; # delete and respawn the empire
our $dry_run    = 0; # go through the motions, but don't change the database
our $add        = 0; # the number of colonies to add

GetOptions(
    'quiet'      => \$quiet,  
    'respawn'    => \$respawn,
    'dry_run'    => \$dry_run,
    'add=i'      => \$add,
);

out('Started');
my $start = time;

out('Loading DB');
our $db     = Lacuna->db;
my $config  = Lacuna->config;
my $empires = $db->resultset('Lacuna::DB::Result::Empire');
my $empire;

if ($respawn) {
    # with 'respawn' we delete and re-create the whole empire
    out('Re-Spawning Empire');
    $empire = $empires->find(-9);

    if (defined $empire) {
        out('Deleting existing empire');
        $empire->delete unless $dry_run;
    }
}

$empire = $empires->find(-9);
if (not defined $empire) {
    out('Creating new empire');
    $empire = create_empire() unless $dry_run;
}

# We need to determine how many DeLambert colonies to add to each zone
# we ignore the neutral zone
# we ignore zone 0|0 since it is already highly occupied already
# we want to put DeLambert colonies in zones such that the ration of other empires
# colonies to DeLambert colonies is fairly constant.
#
# First work out how many bodies are occupied in each zone which are *not* DeLambert
my @zone_body = $db->resultset('Lacuna::DB::Result::Map::Body')->search({
    -and => [
        empire_id   => {'!=' => undef}, 
        empire_id   => {'!=' => $empire->id},
        zone        => {'!=' => '0|0'},         # Central zone is too populated
        zone        => {'!=' => '3|0'},         # Ignore the neutral zone
    ],
},{
    group_by => [qw(zone)],
    select => [
        'zone',
        { count => 'id', -as => 'count_bodies'},
    ],
    as => ['zone','total_bodies'],
    order_by => {-desc => 'count_bodies'},
});

out("There are ".scalar(@zone_body)." bodies occupied by empires");
out("    Zone\tCount");
my $total_bodies = 0;
for my $zone (@zone_body) {
    out("    ".$zone->zone."\t".$zone->get_column('total_bodies'));
    $total_bodies += $zone->get_column('total_bodies');
}
out("    Total\t$total_bodies");

# Now, how many deLambert bodies are in each zone
my @zone_delambert = $db->resultset('Lacuna::DB::Result::Map::Body')->search({
    empire_id => $empire->id,
},{
    group_by => [qw(zone)],
    select => [
        'zone',
        { count => 'id', -as => 'count_bodies'},
    ],
    as => ['zone','total_bodies'],
    order_by => {-desc => 'count_bodies'},
});

out("There are ".scalar(@zone_delambert)." bodies occupied by DeLamberti");
out("    Zone\tCount");
my $total_delamberti = 0;
for my $zone (@zone_delambert) {
    out("    ".$zone->zone."\t".$zone->get_column('total_bodies'));
    $total_delamberti += $zone->get_column('total_bodies');
}
out("    Total\t$total_delamberti");

# Now we know how many empires are in each zone, and how many DeLamberti
# we can determine which zones have the lowest proportion of DeLamberti
# and add new one's there.
#
for (1..$add) {
    out("Adding a new colony");

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

sub create_empire {
    out('Creating empire...');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({
        id                      => -9,
        name                    => 'DeLambert',
        stage                   => 'founded',
        date_created            => DateTime->now,
        status_message          => 'We come in peace!',
        description             => 'A peaceful trading empire',
        password                => Lacuna::DB::Result::Empire->encrypt_password(rand(99999999)),
        species_name            => 'DeLamberti',
        species_description     => 'A strong species who prefer high G. worlds.',
        min_orbit               => 1,
        max_orbit               => 7,
        manufacturing_affinity  => 2, # cost of building new stuff
        deception_affinity      => 7, # spying ability
        research_affinity       => 2, # cost of upgrading
        management_affinity     => 7, # speed to build
        farming_affinity        => 1, # food
        mining_affinity         => 1, # minerals
        science_affinity        => 7, # energy, propultion, and other tech
        environmental_affinity  => 2, # waste and water
        political_affinity      => 1, # happiness
        trade_affinity          => 7, # speed of cargoships, and amount of cargo hauled
        growth_affinity         => 1, # price and speed of colony ships, and planetary command center start level
    });

    out('Find home planet...');
    my $bodies  = $db->resultset('Lacuna::DB::Result::Map::Body');
    my $zone    = $bodies->get_column('zone')->min;
    my $home    = $bodies->search({
        size    => { '>=' => 110}, 
        zone    => $zone,
        empire_id  => undef,
    },{rows=>1})->single;

    $empire->insert;
    $empire->found($home);
    create_colony($home);
    return $empire;
}

sub create_colony {


}

