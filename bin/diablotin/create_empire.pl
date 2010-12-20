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
GetOptions(
    'quiet'         => \$quiet,  
);



out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

out('Creating empire...');
my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({
    id                  => -2,
    name                => 'Diablotin',
    stage               => 'founded',
    date_created        => DateTime->now,
    status_message      => 'Vous êtes le bouffon!',
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
my $home = $bodies->search({size => { between => [ 40, 49 ] }, orbit => 7, zone => $zone },{rows=>1})->single;
$empire->insert;
$empire->found($home);

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


