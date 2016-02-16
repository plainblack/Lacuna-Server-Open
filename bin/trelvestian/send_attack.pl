use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use AnyEvent;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,
);

use Fcntl qw(:flock);
# stop multiple copies from running
unless (flock(DATA, LOCK_EX|LOCK_NB)) {
    print "$0 is already running. Exiting.\n";
    exit(1);
}


out('Started');
my $start = time;


out('Loading DB');
our $db = Lacuna->db;
our $ai = Lacuna::AI::Trelvestian->new;

my $config = Lacuna->config;

out('Looping through colonies...');
my $colonies = $ai->empire->planets;
my @attacks;
while (my $attacking_colony = $colonies->next) {
    out('Found colony to attack from named '.$attacking_colony->name);
    out('Finding target body to attack...');
    my $target_colony = $attacking_colony->get_last_attacked_by;
    next unless defined $target_colony;
    my @ships = qw(sweeper snark snark2 snark3);
    out('Attacking '.$target_colony->name);
    push @attacks, $ai->start_attack($attacking_colony, $target_colony, \@ships);
    $attacking_colony->delete_last_attacked_by;
}

out("Waiting on attacks...");
foreach my $attack (@attacks) {
    $attack->recv if defined $attack;
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

__DATA__
This exists so flock() code above works.
DO NOT REMOVE THIS DATA SECTION.
