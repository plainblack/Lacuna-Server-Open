use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;

$|=1;
our $quiet;
our $add_one;
GetOptions(
    quiet           => \$quiet,
#    addone          => \$add_one,
);


out('Started');
my $start = time;
out('Loading DB');
our $db = Lacuna->db;
my $config = Lacuna->config;
my $empires = $db->resultset('Lacuna::DB::Result::Empire');
my $ai = Lacuna::AI::Jackpot->new;
my $viable_colonies = $db->resultset('Lacuna::DB::Result::Map::Body')->search(
                { zone => '0|0', empire_id => undef, size => { between => [40,60]},
                  x => { between => [-50,50]}, y => {between => [-50,50]}},
                { rows => 1, order_by => 'rand()' }
                );
my $jackpot = $empires->find(-4);
unless (defined $jackpot) {
    out('Creating new empire');
    $jackpot = $ai->create_empire();
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


