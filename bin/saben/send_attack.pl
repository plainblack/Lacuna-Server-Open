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
    sleep randint(0, 60*60*12); # attack anytime in the next 12 hours.
}


out('Loading DB');
our $db = Lacuna->db;
our $ai = Lacuna::AI::Saben->new;

my $config = Lacuna->config;
my $cache = Lacuna->cache;

out('Looping through colonies...');
my $colonies = $ai->empire->planets;
my @attacks;
while (my $attacking_colony = $colonies->next) {
    out('Found colony to attack from named '.$attacking_colony->name);

    $ai->destroy_world($attacking_colony);

    out('Finding target body to attack...');
    my $targets = $db->resultset('Lacuna::DB::Result::Map::Body')->search({
        empire_id                   => { '>' => 1 },
        is_isolationist             => 0,
        university_level            => { '>=' => 16 },
        zone                        => $attacking_colony->zone,
    },
    {
        order_by    => 'rand()',
        join        => 'empire',
        rows        => 2,
    });
    my $target_colony = $targets->next;
    if (defined $target_colony && !$cache->get('saben'.$attacking_colony->id.'-'.$target_colony->empire_id)) {
        out('Attacking '.$target_colony->name.' with scanners and scows');
        push @attacks, $ai->start_attack($attacking_colony, $target_colony, [qw(scanner scow)]);
        $cache->set('saben'.$attacking_colony->id.'-'.$target_colony->empire_id, 1, 60 * 60 * 48);
    }
    $target_colony = $targets->next;
    if (defined $target_colony && !$cache->get('saben'.$attacking_colony->id.'-'.$target_colony->empire_id)) {
        out('Attacking '.$target_colony->name.' with sweepers and bleeders and snarks');
        push @attacks, $ai->start_attack($attacking_colony, $target_colony, [qw(sweeper bleeder snark1 snark2 snark3)]);
        $cache->set('saben'.$attacking_colony->id.'-'.$target_colony->empire_id, 1, 60 * 60 * 48);
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
