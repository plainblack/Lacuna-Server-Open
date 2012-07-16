use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use AnyEvent;
$|=1;
our $quiet;
our $randomize;
GetOptions(
    'quiet'         => \$quiet,
    'randomize'         => \$randomize,
);


use Fcntl qw(:flock);
# stop multiple copies from running
unless (flock(DATA, LOCK_EX|LOCK_NB)) {
    print "$0 is already running. Exiting.\n";
    exit(1);
}


out('Started');
my $start = time;

if ($randomize) {
    sleep randint(0, 60*60*18); # attack anytime in the next 18 hours.
}


out('Loading DB');
our $db = Lacuna->db;
our $ai = Lacuna::AI::Diablotin->new;

my $config = Lacuna->config;

out('Looping through colonies...');
my $colonies = $ai->empire->planets;
my @attacks;
while (my $attacking_colony = $colonies->next) {
    out('Found colony to attack from named '.$attacking_colony->name);
    out('Finding target body to attack...');
    my $targets = $db->resultset('Lacuna::DB::Result::Map::Body')->search({
        empire_id                   => { '>' => 1 },
        'empire.is_isolationist'    => 0,
    },
    {
        order_by    => 'rand()',
        rows        => 4,
        join        => 'empire',
    });
    my @ships = qw(thud placebo placebo2 placebo3);
    while (my $target_colony = $targets->next) {
        if ($target_colony->in_neutral_area) {
            out($target_colony->name." in Neutral Area, skipping.");
            next;
        }
        out('Attacking '.$target_colony->name);
        push @attacks, $ai->start_attack($attacking_colony, $target_colony, [shift @ships]);
    }
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
