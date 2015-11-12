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

out('Sanitize derilict space stations');
# sanitize derilict space stations
my $stations_rs = $db->resultset('Lacuna::DB::Result::Map::Body');
my @stations = $stations_rs->search({ class => 'Lacuna::DB::Result::Map::Body::Planet::Station' })->get_column('id')->all;
foreach my $id (@stations) {
    my $station = $stations_rs->find($id);
    out('Checking '.$station->name);
    if (! defined $station->command && ! defined $station->parliament) {
        out('Sanitizing');
        $station->sanitize;
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


