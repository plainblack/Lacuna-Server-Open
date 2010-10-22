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

out('Ticking planets');
my $planets_rs = $db->resultset('Lacuna::DB::Result::Map::Body');
my @planets = $planets_rs->search({ empire_id   => {'>' => 0} })->get_column('id')->all;
foreach my $id (@planets) {
    my $planet = $planets_rs->find($id);
    out('Ticking '.$planet->name);
    $planet->tick;
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


