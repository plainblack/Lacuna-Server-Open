use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use List::Util qw(max);
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,
);

out('Started');
my $start = time;

out('Loading Empires');
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire');
my $cache = Lacuna->cache;
my $lec = Lacuna::DB::Result::Empire->lacuna_expanse_corp;

out('Checking space stations.');
my %victory_empire;
my $stations = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({class => 'Lacuna::DB::Result::Map::Body::Planet::Station'});
my $message = '';
while (my $station = $stations->next) {
    my $stars = $station->influence_spent;
    $message .= sprintf("The station {Starmap %s %s %s}, owned by {Empire %s %s}, controls %d stars.\n", 
        $station->x, $station->y, $station->name, $station->empire_id, $station->empire->name, $stars);
    if ( $stars >= 25 ) {
        $victory_empire{$station->empire_id} = $stars;
    }
}

if (scalar keys %victory_empire) {
    $cache->set('server','status','Game Over', 60 * 60 * 24 * 30);
}
elsif (DateTime->now->hour == 3 ) {
    while (my $empire = $empires->next) {
        $empire->send_message(
            tags        => ['Alert'],
            from        => $lec,
            body        => $message,
            subject     => 'Situation Update',
        );
    }
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


