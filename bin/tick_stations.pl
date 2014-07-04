use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server/lib';
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use App::Daemon qw(daemonize );
use Data::Dumper;
use Try::Tiny;
use Log::Log4perl qw(:levels);

# --------------------------------------------------------------------
# Description:
# Calculating the influence from an SS on every change of the SS (e.g.
# every building upgrade, downgrade, damage etc.) would be excessive.
#
# It suffices to check every half hour or so with a simple DB query to
# find all SS that need to be recalculated.
#
# This allows us to perform some optimisations. 
#
# First we check all SS that need to be recalculated, we add (or delete)
# entries in the 'Influence' table and all stars which are affected are
# marked for a 'recalc'.
#
# Having processed all SS we then go through and recalc the influence on
# each star so marked.
#
# This means we don't un-necessarily calculate the influence on each star
# twice (e.g. when multiple nearby SS all change in a short space of time)
#

# --------------------------------------------------------------------
# command line arguments:
#
our $quiet      = 1;

GetOptions(
    'quiet!'        => \$quiet,
);

my $start = time;
my $config = Lacuna->config;

# --------------------------------------------------------------------
# Main processing loop

out('Started') unless $quiet;

my $station_rs = Lacuna->db->resultset('Map::Body')->search({
    station_recalc  => 1,
});
while (my $station = $station_rs->next) {
    out('Processing station '.$station->name) unless $quiet;
    $station->recalc_influence;
}
# Now check if there are any stars to recalculate
my $star_rs = Lacuna->db->resultset('Map::Star')->search({
    recalc => 1,
});
while (my $star = $star_rs->next) {
    out('Processing star '.$star->name) unless $quiet;
    $star->recalc_influence;
}

my $finish = time;
out('Finished');
out(int(($finish - $start)/60)." minutes have elapsed");
exit 0;

###############
## SUBROUTINES
###############

sub out {
    my ($message) = @_;
    say $message unless $quiet;
    my $logger = Log::Log4perl->get_logger;
    $logger->info($message);
}

