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
    id                  => -1,
    name                => 'Sābēn Demesne',
    stage               => 'founded',
    date_created        => DateTime->now,
    status_message      => 'Waging war!',
    description         => 'We see you looking at our description. Know this, we have looked at your description as well, and found it lacking. You do not deserve to share our Demesne.',
    password            => Lacuna::DB::Result::Empire->encrypt_password(rand(99999999)),
    species_name            => 'Sābēn',
    species_description     => 'A solitary people who wish to be left alone.',
    min_orbit               => 1,
    max_orbit               => 7,
    manufacturing_affinity  => 4, # cost of building new stuff
    deception_affinity      => 7, # spying ability
    research_affinity       => 1, # cost of upgrading
    management_affinity     => 7, # speed to build
    farming_affinity        => 1, # food
    mining_affinity         => 1, # minerals
    science_affinity        => 7, # energy, propultion, and other tech
    environmental_affinity  => 1, # waste and water
    political_affinity      => 1, # happiness
    trade_affinity          => 7, # speed of cargoships, and amount of cargo hauled
    growth_affinity         => 1, # price and speed of colony ships, and planetary command center start level
});

out('Find home planet...');
my $bodies = $db->resultset('Lacuna::DB::Result::Map::Body');
my $zone = $bodies->get_column('zone')->max;
my $home = $bodies->search({size => 35, zone => $zone })->first;
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


