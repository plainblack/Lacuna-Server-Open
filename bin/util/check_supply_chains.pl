use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

out('Getting Supply Chains');
my $chains = $db->resultset('Lacuna::DB::Result::SupplyChain')->search;

while ( my $chain = $chains->next) {
    my $supply_body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($chain->planet_id);
    my $target_body = $db->resultset('Lacuna::DB::Result::Map::Body')->find($chain->target_id);

    if ($supply_body->empire->alliance_id != $target_body->empire->alliance_id) {
        my $saname = "";
        my $taname = "";
        $saname = $supply_body->empire->alliance->name if ($supply_body->empire->alliance);
        $taname = $target_body->empire->alliance->name if ($target_body->empire->alliance);
        printf "Cid: %7s %s:%s:%s:%s -> %s:%s:%s:%s to %s\n",
               $chain->id,
               $supply_body->name,
               $supply_body->id,
               $supply_body->empire->name,
               $saname,
               $target_body->name,
               $target_body->id,
               $target_body->empire->name,
               $taname,
               $target_body->get_type;
    }
}

###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}
